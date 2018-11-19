component = node.engineyard.environment.ruby

ruby_mask = nil
ruby_dependencies = {}
do_upgrade_eselect_ruby = false

if component[:version] =~ /^2\.0[\d\.]*\b/
  ruby_mask = '-ruby_targets_ruby20'
  ruby_dependencies = {
    'dev-ruby/rubygems' => '1.8.24-r1'
  }
end

if component[:version] =~ /^2\.1[\d\.]*\b/
  ruby_mask = '-ruby_targets_ruby21'
  ruby_dependencies = {
    "dev-ruby/json"     => "1.8.1",
    "dev-ruby/racc"     => "1.4.11",
    "dev-ruby/rake"     => "0.9.6-r1",
    "dev-ruby/rdoc"     => "4.0.1-r2",
    "dev-ruby/rubygems" => "2.0.14",
  }
end

if component[:version] =~ /^2\.2[\d\.]*\b/
  ruby_mask = '-ruby_targets_ruby22'
  ruby_dependencies = {
    "dev-ruby/json"     => "1.8.2",
    "dev-ruby/racc"     => "1.4.11-r1",
    "dev-ruby/rake"     => "0.9.6-r2",
    "dev-ruby/rdoc"     => "4.0.1-r3",
    "dev-ruby/rubygems" => "2.0.14-r1",
  }
end

if component[:version] =~ /^2\.3[\d\.]*\b/
  ruby_mask = '-ruby_targets_ruby23'
  ruby_dependencies = {
    "dev-ruby/json"     => "1.8.2-r1",
    "dev-ruby/racc"     => "1.4.11-r2",
    "dev-ruby/rake"     => "0.9.6-r3",
    "dev-ruby/rdoc"     => "4.0.1-r4",
    "dev-ruby/rubygems" => "2.0.14-r2",
  }
end

if component[:version] =~ /^2\.4[\d\.]*\b/
  ruby_mask = '-ruby_targets_ruby24'
  ruby_dependencies = {
    "dev-ruby/json"         => "2.0.3",
    "dev-ruby/racc"         => "1.4.14-r1",
    "dev-ruby/rake"         => "12.0.0",
    "dev-ruby/rdoc"         => "5.1.0",
    "dev-ruby/rubygems"     => "2.6.14",
    "dev-ruby/did_you_mean" => "1.1.0",
    "dev-ruby/kpeg"         => "1.1.0",
    "dev-ruby/minitest"     => "5.10.1",
    "dev-ruby/net-telnet"   => "0.1.1-r2",
    "dev-ruby/power_assert" => "0.4.1",
    "dev-ruby/test-unit"    => "3.2.3",
    "dev-ruby/xmlrpc"       => "0.2.1",
    "virtual/rubygems"      => "12",
  }
end

if component[:version] =~ /^2\.5[\d\.]*\b/
  ruby_mask = '-ruby_targets_ruby25'
  do_upgrade_eselect_ruby = true
  ruby_dependencies = {
    "dev-ruby/json"         => "2.0.3-r1",
    "dev-ruby/racc"         => "1.4.14-r2",
    "dev-ruby/rake"         => "12.3.0",
    "dev-ruby/rdoc"         => "6.0.3",
    "dev-ruby/rubygems"     => "2.7.6",
    "dev-ruby/did_you_mean" => "1.2.0",
    "dev-ruby/kpeg"         => "1.1.0-r1",
    "dev-ruby/minitest"     => "5.10.3",
    "dev-ruby/net-telnet"   => "0.1.1-r3",
    "dev-ruby/power_assert" => "1.1.1",
    "dev-ruby/test-unit"    => "3.2.7",
    "dev-ruby/xmlrpc"       => "0.3.0",
    "virtual/rubygems"      => "13",
  }
end

unmask_package component[:package] do
  version component[:version]
  unmaskfile "ruby"
end

use_mask ruby_mask do
  mask_file "ruby"
  only_if "ruby_mask"
end

package "app-eselect/eselect-ruby" do
  action :upgrade
  only_if { do_upgrade_eselect_ruby }
end

ruby_dependencies.each do |dep, dep_version|
  enable_package dep do
    version dep_version
  end
end

include_recipe 'ruby::common'

execute "install-modern-rack" do
  command "gem install rack -v 1.0.1"
  only_if { component[:full_version] =~ /^ruby-1\.8\.6/ }
end
