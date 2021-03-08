include_attribute "kkafka"
include_attribute "ndb"

default['onlinefs']['version']                = 1.0 
default['onlinefs']['download_url']           = "#{node['download_url']}/onlinefs/#{node['onlinefs']['version']}/onlinefs.tgz"

default['onlinefs']['user']                   = "onlinefs"
default['onlinefs']['group']                  = "onlinefs"

default['onlinefs']['home']                   = "#{node['install']['dir']}/onlinefs" 
default['onlinefs']['etc']                    = "#{node['install']['home']}/etc" 
default['onlinefs']['logs']                   = "#{node['install']['home']}/logs" 

default['onlinefs']['hopsworks']['email']     = "onlinefs@hopsworks.ai"
default['onlinefs']['hopsworks']['password']  = "onlinefspw"

default['onlinefs']['monitoring']             = 12800
