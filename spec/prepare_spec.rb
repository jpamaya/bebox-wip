require 'spec_helper'
require_relative '../spec/factories/node.rb'
require 'pry'

describe 'test_06: Bebox::Node' do

  describe 'Prepare nodes' do

    let(:nodes) { 1.times.map{|index| build(:node, :created, hostname: "node#{index}.server1.test", ip: "192.168.0.7#{index}")} }
    let(:project_root) { "#{Dir.pwd}/tmp/pname" }
    let(:environment) { 'vagrant' }
    let(:project_name) {'pname'}
    let(:vagrant_box_base) {'~/.bebox/boxes/ubuntu-server-12042-x64-vbox4210-nocm.box'}

    context 'pre vagrant prepare' do
      it 'should generate the Vagrantfile' do
        Bebox::Node.generate_vagrantfile(project_root, nodes)
        vagrantfile_content = File.read("#{project_root}/Vagrantfile").gsub(/\s+/, ' ').strip
        vagrantfile_output_content = File.read("spec/fixtures/node/Vagrantfile.test").gsub(/\s+/, ' ').strip
        expect(vagrantfile_content).to eq(vagrantfile_output_content)
      end
      it 'should regenerate the vagrant deploy file' do
        Bebox::Node.regenerate_deploy_file(project_root, environment, nodes)
        vagrant_deploy_content = File.read("#{project_root}/config/deploy/vagrant.rb").gsub(/\s+/, ' ').strip
        vagrant_deploy_output_content = File.read("spec/fixtures/node/vagrant_deploy.test").gsub(/\s+/, ' ').strip
        expect(vagrant_deploy_content).to eq(vagrant_deploy_output_content)
      end
    end

    context 'vagrant prepare' do
      describe 'Configure the hosts file' do
        it 'should create a hosts backup file' do
          node = nodes.first
          puts 'Please provide your account password, if ask you, to configure the local hosts file.'
          original_hosts_content = File.read("#{node.local_hosts_path}/hosts").gsub(/\s+/, ' ').strip
          nodes.each{|node| node.backup_local_hosts(project_name)}
          hosts_backup_file = "#{node.local_hosts_path}/hosts_before_bebox_#{project_name}"
          expect(File).to exist(hosts_backup_file)
          hosts_backup_content = File.read(hosts_backup_file).gsub(/\s+/, ' ').strip
          expect(original_hosts_content).to eq(hosts_backup_content)
        end

        it 'should add the hosts config to hosts file' do
          nodes.each{|node| node.add_to_local_hosts}
          node = nodes.first
          hosts_content = File.read("#{node.local_hosts_path}/hosts").gsub(/\s+/, ' ').strip
          expect(hosts_content).to include(*nodes.map{|node| "#{node.ip} #{node.hostname}"})
        end
      end

      describe 'vagrant setup' do
        it 'should add the node to vagrant' do
          vagrant_box_names_expected = nodes.map{|node| "#{project_name}-#{node.hostname}"}
          nodes.each{|node| node.add_vagrant_node(project_name, vagrant_box_base)}
          node = nodes.first
          expect(node.installed_vagrant_box_names).to include(*vagrant_box_names_expected)
        end

        it 'should up the vagrant boxes' do
          nodes_running = true
          Bebox::Node.up_vagrant_nodes(project_root)
          vagrant_status = Bebox::Node.vagrant_nodes_status(project_root)
          nodes.each{|node| nodes_running &= (vagrant_status =~ /#{node.hostname}\s+running/).nil? ? false : true}
          expect(nodes_running).to eq(true)
        end

        it 'should connect to vagrant box through ssh' do
          connection_successful = true
          nodes.each do |node|
            `ssh -q -oStrictHostKeyChecking=no -i ~/.vagrant.d/insecure_private_key -l vagrant #{node.ip} exit`
            connection_successful &= ($?.exitstatus == 0)
          end
          expect(connection_successful).to eq(true)
        end
      end
    end
  end
end