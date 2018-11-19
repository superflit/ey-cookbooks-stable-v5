use_inline_resources
# Cookbook:: newrelic
# Provider:: default

include NewrelicHelpers
include PhpHelpers

def why_run_supported?
  true
end

action :install do
  case new_resource.run_type
  when "rpm"
    if ruby_app?
      # Nothing to see here. Customer adds newrelic_rpm gem to application
    elsif php_app?
      install_php_rpm
      configure_php_rpm
    end
  end
  new_resource.updated_by_last_action true
end

private

def ruby_app?
  ['rails2', 'rails3', 'rails4', 'ruby'].include? new_resource.app_type
end

def php_app?
  new_resource.app_type == 'php'
end


def install_php_rpm
  extensions_dir = case node['php']['minor_version']
  when '5.6'
    '/usr/lib64/php5.6/lib/extensions/no-debug-non-zts-20131226'
  when '7.0'
    '/usr/lib64/php7.0/lib/extensions/no-debug-non-zts-20151012'
  end

  if extensions_dir
    directory extensions_dir do
      owner 'root'
      group 'root'
      mode 0755
      action :create
      recursive true
    end
  end

  directory "/opt/php_rpm" do
    owner 'root'
    group 'root'
    mode 0755
    action :create
    recursive true
  end

  remote_file "/opt/php_rpm/newrelic-php5-#{node['newrelic']['php_rpm_version']}-linux.tar.gz" do
    source "http://download.newrelic.com/php_agent/archive/#{node['newrelic']['php_rpm_version']}/newrelic-php5-#{node['newrelic']['php_rpm_version']}-linux.tar.gz"
    action :create_if_missing
  end

  # Install newrelic PHP as 'root' user using silent install
  bash "install_newrelic_php" do
    user 'root'
    cwd '/opt/php_rpm/'
    code <<-EOH
      export NR_INSTALL_SILENT='true'
      export NR_INSTALL_KEY="#{newrelic_license_key}"
      gzip -dc newrelic-php5-#{node['newrelic']['php_rpm_version']}-linux.tar.gz | tar xf -
      cd newrelic-php5-#{node['newrelic']['php_rpm_version']}-linux
      ./newrelic-install install
    EOH
    action :run
  end
end

def configure_php_rpm
  # Write custom newrelic.ini information
  template "/etc/php/cli-php#{node['php']['minor_version']}/ext-active/newrelic.ini" do
    owner "root"
    group "root"
    mode 0644
    backup 0
    source "newrelic.ini.erb"
    variables(
      :app_name    => "#{node.engineyard.environment['name']} / #{new_resource.app_name}",
      :license_key => newrelic_license_key)
  end

  template "/etc/php/fpm-php#{node['php']['minor_version']}/ext-active/newrelic.ini" do
    owner "root"
    group "root"
    mode 0644
    backup 0
    source "newrelic.ini.erb"
    variables(
      :app_name    => "#{node.engineyard.environment['name']} / #{new_resource.app_name}",
      :license_key => newrelic_license_key)
  end

  # Write newrelic.cfg information
  template "/etc/newrelic/newrelic.cfg" do
    owner "root"
    group "root"
    mode 0644
    backup 0
    source "newrelic.cfg.erb"
    variables(
      :license_key => newrelic_license_key,
      :labels => new_resource.labels
    )
    notifies :run, 'execute[restart newrelic-daemon]', :delayed
  end

  # Set up newrelic per application
  #node.dna[:applications].each do |app, data|
  #  file = Chef::Util::FileEdit.new("/data/#{app}/shared/config/fpm-pool.conf")
  #  file.insert_line_if_no_match("/php_value[newrelic.appname] = \"#{app_name}\"/", "php_value[newrelic.appname] = \"#{app_name}\"")
  #  file.write_file
  #end

  # Add newrelic-daemon to monit
  template "/etc/monit.d/newrelic-daemon.monitrc" do
    owner "root"
    group "root"
    mode 0644
    source "newrelic-daemon.monitrc.erb"
    notifies :run, 'execute[monit reload]', :immediately
  end

  # cookbooks/php/libraries/php_helpers.rb
  #restart_fpm
  if ['app_master', 'app', 'solo'].include?(node['dna']['instance_role'])
    execute 'monit restart all -g php-fpm' do
      action :run
    end

    service "nginx" do
      action :restart
    end
  end

  execute "monit reload" do
    action :nothing
    notifies :run, 'execute[restart newrelic-daemon]', :delayed
  end

  execute "restart newrelic-daemon" do
    action :nothing
    command "sleep 10s && monit restart newrelic-daemon || true"
  end
end
