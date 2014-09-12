require 'spec_helper'

require_relative '../factories/profile.rb'

describe 'Test 05: Bebox::ProfileWizard' do

  subject { Bebox::ProfileWizard.new }

  let(:profile) { build(:profile) }

  before :each do
    $stdout.stub(:write)
  end

  context '00: profile not exist' do
    it 'creates a new profile with wizard' do
      Bebox::Profile.any_instance.stub(:create) { true }
      output = subject.create_new_profile(profile.project_root, profile.name, profile.path)
      expect(output).to eq(true)
    end

    it 'not creates a new profile with invalid name' do
      invalid_name = '0_profile'
      output = subject.create_new_profile(profile.project_root, invalid_name, profile.path)
      expect(output).to eq(nil)
    end

    it 'not creates a new profile with invalid path' do
      invalid_path = 'and/00'
      output = subject.create_new_profile(profile.project_root, profile.name, invalid_path)
      expect(output).to eq(nil)
    end

    it 'list profiles with wizard' do
        Bebox::Profile.stub(:list) {[]}
       output = subject.list_profiles(profile.project_root)
       expect(output).to eq([])
    end
  end

  context '01: profile not exist' do

    it 'removes a profile with wizard' do
      Bebox::Profile.stub(:list) { [profile.relative_path] }
      Bebox::Profile.any_instance.stub(:remove) { true }
      $stdin.stub(:gets).and_return(profile.relative_path, 'y')
      output = subject.remove_profile(profile.project_root)
      expect(output).to eq(true)
    end
  end

  it 'can not remove a profile if not exist any profile with wizard' do
    Bebox::Profile.stub(:list) {[]}
    output = subject.remove_profile(profile.project_root)
    expect(output).to eq(nil)
  end
end