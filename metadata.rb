name              "onlinefs"
maintainer        "Logical Clocks"
maintainer_email  'info@logicalclocks.com'
license           'GPLv3'
description       'Installs/Configures the Hopsworks online feature store service'
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "2.4.0"

recipe "onlinefs::default", "Configures the Hopsworks online feature store service"

depends 'kkafka'
depends 'ndb'
depends 'hops'
depends 'kagent'
depends 'consul'

attribute "onlinefs/user",
          :description => "User to run the online feature store service",
          :type => "string"

attribute "onlinefs/user_id",
          :description => "onlinefs user id. Default: 1521",
          :type => "string"

attribute "onlinefs/group",
          :description => "Group of the user running the online feature store service",
          :type => "string"

attribute "onlinefs/group_id",
          :description => "onlinefs group id. Default: 1516",
          :type => "string"

attribute "onlinefs/service/thread_number",
          :description => "number of threads reading from kafka and writing to rondb",
          :type => "string"

attribute "onlinefs/monitoring",
          :description => "Port on which the monitoring page is available",
          :type => "string"
