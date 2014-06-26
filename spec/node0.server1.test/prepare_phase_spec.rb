require 'spec_helper'
require_relative '../vagrant_spec_helper.rb'
require_relative '../factories/node.rb'

describe 'test_07: Node prepared' do

  let(:node) { build(:node) }

  before(:all) do
     node.prepare
  end

  context 'vagrant prepared' do
    describe interface('eth1') do
      it { should have_ipv4_address(node.ip) }
    end

    describe host('node0.server1.test') do
      it { should be_resolvable }
      it { should be_reachable }
      it { should be_reachable.with( :port => 22 ) }
    end

    describe user('vagrant') do
      it { should exist }
    end
  end

  context 'all environments prepared' do
    describe command('hostname') do
      it 'should configure the hostname' do
        should return_stdout node.hostname
      end
    end

    describe command("dpkg -s #{Bebox::Project.so_dependencies} | grep Status") do
      it 'should install ubuntu dependencies' do
        should return_stdout /(Status: install ok installed\s*){#{Bebox::Project.so_dependencies.split(' ').size}}/
      end
    end

    describe package('puppet') do
      it { should be_installed }
    end
  end
end