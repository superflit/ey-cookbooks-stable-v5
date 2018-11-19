# Configuration Options
  # recommended versions as of February 6, 2017
  #  - Postgres: 9.2.16, 9.3.12, 9.4.8, 9.5.3
  #  - Postgres: 9.5.5     # !review warnings! in the Readme
  #  - MySQL: 5.6.32.78.1, 5.7.14.8
  #  - Available versions under:
  #    - Postgres: /engineyard/portage/engineyard/dev-db/postgresql-server/*.ebuild
  #    - MySQL: /engineyard/portage/engineyard/dev-db/percona-server/*.ebuild
install_packages=[
  {
    :server => 'postgresql-server',   # postgresql-server or percona-server
    :version => '9.4.4',
    :default_slot => false,                   # postgres packages only, use true only with no_db environments, makes this package the system default
  },
  ]

if ['app', 'app_master', 'util'].include?(node.dna['instance_role'])
  install_packages.each do |package|
    major = "#{package[:version].split('.')[0]}.#{package[:version].split('.')[1]}"

    if package[:version] != '9.5.5'

      ey_cloud_report "Installing db_client_lib #{package[:server]}" do
        message "installing #{package[:server]}-#{package[:version]}"
      end


      if package[:server] == 'postgresql-server'

        enable_package "dev-libs/ossp-uuid" do
          version "1.6*"
        end

        enable_package "dev-python/python-exec" do
          version '0.2'
          only_if { package[:version] >= '9.3' }
        end

        enable_package "dev-db/postgresql-base" do
          version package[:version]
        end

        enable_package "dev-db/postgresql-server" do
          version package[:version]
        end

        package "dev-db/postgresql-server" do
          version package[:version]
          action :install
        end

        execute "activate_postgres_#{major}" do
          command "eselect postgresql set #{major}"
          action :run
          only_if { package[:default_slot] }
        end

      elsif package[:server] == 'percona-server'

        unmask_path = "/etc/portage/package.unmask/mysql"
        unmask_body = "=virtual/mysql-5.7\n=dev-db/#{package[:server]}-#{package[:version]}"

        update_file "unmasking #{package[:server]} #{package[:version]}" do
          action :append
          path unmask_path
          body unmask_body
          not_if "grep '#{unmask_body}' #{unmask_path}"
        end

        enable_package "virtual/mysql" do
          version major
        end

        enable_package "virtual/libmysqlclient" do
          version "20"
        end
        enable_package "dev-db/#{package[:server]}" do
          version package[:version]
        end

        enable_package "dev-util/cmake" do
          version '2.6.2'
        end

        package "dev-db/#{package[:server]}" do
          version package[:version]
          action :install
        end

      else
        ey_cloud_report "Installation of #{package[:server]}-#{package[:version]} failed:" do
          message "this server and version is unknown."
        end
      end


  ey_cloud_report "Installation of db_client_libs" do
    message "complete!"
  end
end
