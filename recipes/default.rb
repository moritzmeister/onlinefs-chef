group node['onlinefs']['group'] do
  action :create
  not_if "getent group #{node['onlinefs']['group']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

user node['onlinefs']['user'] do
  home node['onlinefs']['user-home']
  gid node['onlinefs']['group']
  action :create
  shell "/bin/nologin"
  manage_home true
  system true
  not_if "getent passwd #{node['onlinefs']['user']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

# Create the directories for configuration files and logs
['home', 'etc', 'logs'].each {|dir|
   directory node['onlinefs'][dir] do
     owner node['onlinefs']['user']
     group node['onlinefs']['group']
     mode "0750"
     action :create
   end
}

# Generate a certificate
crypto_dir = x509_helper.get_crypto_dir(node['onlinefs']['user'])
kagent_hopsify "Generate x.509" do
  user node['onlinefs']['user']
  crypto_directory crypto_dir
  action :generate_x509
  not_if { node["kagent"]["enabled"] == "false" }
end

# Generate an API key
ruby_block 'fetch-api-key' do
  block do
    require 'net/https'
    require 'http-cookie'
    require 'json'

    hopsworks_fqdn = consul_helper.get_service_fqdn("hopsworks.glassfish")
    hopsworks_endpoint = "https://#{hopsworks_fqdn}:#{node['hopsworks']['internal']['port']}"
    url = URI.parse("#{hopsworks_endpoint}/hopsworks-api/api/auth/service")
    api_key_url = URI.parse("#{hopsworks_endpoint}/hopsworks-api/api/users/apiKey")

    params =  {
      :email => node['onlinefs']['hopsworks']['email'],
      :password => node['onlinefs']['hopsworks']["password"]
    }

    api_key_params = {
      :name => "onlinefs",
      # check with fabio which scopes are needed
      :scope => "FEATURESTORE,KAFKA,PROJECT"
    }

    http = Net::HTTP.new(url.host, url.port)
    http.read_timeout = 120
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    jar = ::HTTP::CookieJar.new

    http.start do |connection|

      request = Net::HTTP::Post.new(url)
      request.set_form_data(params, '&')
      response = connection.request(request)

      if( response.is_a?( Net::HTTPSuccess ) )
          # your request was successful
          puts "The Response -> #{response.body}"

          response.get_fields('Set-Cookie').each do |value|
            jar.parse(value, url)
          end

          request = Net::HTTP::Post.new(api_key_url)
          request.set_form_data(api_key_params, '&')
          request['Content-Type'] = "application/json"
          request['Cookie'] = ::HTTP::Cookie.cookie_value(jar.cookies(api_key_url))
          request['Authorization'] = response['Authorization']
          response = connection.request(request)

          if ( response.is_a? (Net::HTTPSuccess))
            json_response = ::JSON.parse(response.body)
            api_key = json_response['signedCert']
          else
            puts response.body
            raise "Error creating onlinefs api-key"
          end
      else
          puts response.body
          raise "Error logging in"
      end
    end
  end
end

# Template the configuration file
kafka_fqdn = consul_helper.get_service_fqdn("broker.kafka")
mgm_fqdn = consul_helper.get_service_fqdn("mgm.rondb")
template "#{node['onlinefs']['etc']}/onlinefs-site.xml" do
  source "onlinefs-site.xml.erb"
  owner node['onlinefs']['user']
  group node['onlinefs']['group']
  mode 0750
  variables( lazy {
    {
      :kafka_fqdn => kafka_fqdn,
      :mgm_fqdn => mgm_fqdn,
      :api_key => api_key
    }
  })
end

template "#{node['onlinefs']['etc']}/log4j.properties" do
  source "log4j.properties.erb"
  owner node['onlinefs']['user']
  group node['onlinefs']['group']
  mode 0750
end

# Download and load the Docker image
image_url = node['onlinefs']['download_url']
base_filename = File.basename(image_url)
remote_file "#{Chef::Config['file_cache_path']}/#{base_filename}" do
  source image_url
  action :create
end

# Load the Docker image
bash "import_image" do
  user "root"
  code <<-EOF
    docker load -i #{Chef::Config['file_cache_path']}/#{base_filename}
  EOF
  not_if "docker image inspect docker.hops.works/onlinefs:#{node['onlinefs']['version']}"
end

# Add Systemd unit file
service_name="onlinefs"
case node['platform_family']
when "rhel"
  systemd_script = "/usr/lib/systemd/system/#{service_name}.service"
else
  systemd_script = "/lib/systemd/system/#{service_name}.service"
end

service service_name do
  provider Chef::Provider::Service::Systemd
  supports :restart => true, :stop => true, :start => true, :status => true
  action :nothing
end

template systemd_script do
  source "#{service_name}.service.erb"
  owner "root"
  group "root"
  mode 0664
  action :create
  if node['services']['enabled'] == "true"
    notifies :enable, "service[#{service_name}]"
  end
  variables({
    :crypto_dir => crypto_dir
  })
end

kagent_config "#{service_name}" do
  action :systemd_reload
end

# Register with kagent
if node['kagent']['enabled'] == "true"
  kagent_config service_name do
    service "feature store"
  end
end

# Register with consul
if service_discovery_enabled()
  # Register online fs with Consul
  consul_service "Registering OnlineFS with Consul" do
    service_definition "onlinefs.hcl.erb"
    action :register
  end
end
