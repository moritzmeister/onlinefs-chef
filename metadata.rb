name              "onlinefs"
maintainer        "Logical Clocks"
maintainer_email  'info@logicalclocks.comm'
license           'GPLv3'
description       'Installs/Configures the Hopsworks online feature store service'
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "2.0.0"

recipe "onlinefs::default", "Configures the Hopsworks online feature store service"
