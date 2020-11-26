require "spec_helper"
require "serverspec"

nodejs_version = /^v10\.\d+\.\d+/
user    = "laserweb"
group   = "laserweb"
groups = case os[:family]
         when "freebsd"
           %w[dialer]
         else
           %w[dialout]
         end
service = "laserweb"
version = "unix"
scm_dest = "/home/laserweb/lw.comm-server"
ports = [8000]

describe group(group) do
  it { should exist }
end

describe user(user) do
  it { should exist }
  it { should belong_to_primary_group group }
  groups.each do |g|
    it { should belong_to_group g }
  end
end

describe command "node --version" do
  its(:stderr) { should be_empty }
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/#{nodejs_version}/) }
end

describe file(scm_dest) do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  it { should be_mode os[:family] == "ubuntu" ? 775 : 755 }
end

describe command "cd #{scm_dest} && git branch" do
  its(:stderr) { should be_empty }
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/^\*\s+#{version}/) }
end

describe service(service) do
  it { should be_enabled }
  it { should be_running }
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end
