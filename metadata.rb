name              "onlinefs"
maintainer        "Logical Clocks"
maintainer_email  'info@logicalclocks.com'
license           'GPLv3'
description       'Installs/Configures the Hopsworks online feature store service'
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "2.2.0"

recipe "onlinefs::default", "Configures the Hopsworks online feature store service"

depends 'kkafka'
depends 'ndb'
depends 'kagent'
depends 'consul'

attribute "onlinefs/service/thread_number",
          :description => "number of threads reading from kafka and writing to rondb",
          :type => "string"
