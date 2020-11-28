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
port = 8001
default_group = case os[:family]
                when /bsd/
                  "wheel"
                else
                  "root"
                end

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

describe file("#{scm_dest}/app/index.js") do
  it { should exist }
  it { should be_file }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

case os[:family]
when "freebsd"
  describe file("/etc/rc.conf.d/laserweb") do
    it { should exist }
    it { should be_file }
    it { should be_owned_by "root" }
    it { should be_grouped_into default_group }
    it { should be_mode 644 }
    its(:content) { should match(/Managed by ansible/) }
    its(:content) { should match(/NODE_ENV=production WEB_PORT=8001 VERBOSE_LEVEL=2/) }
  end
when "ubuntu"
  describe file("/etc/default/laserweb") do
    it { should exist }
    it { should be_file }
    it { should be_owned_by "root" }
    it { should be_grouped_into default_group }
    it { should be_mode 644 }
    its(:content) { should match(/Managed by ansible/) }
    its(:content) { should match(/^NODE_ENV=production$/) }
    its(:content) { should match(/^WEB_PORT=8001$/) }
    its(:content) { should match(/^VERBOSE_LEVEL=2$/) }
  end
end

describe service(service) do
  it { should be_enabled }
  it { should be_running }
end

describe port(port) do
  it { should be_listening }
end

describe command "curl --silent http://127.0.0.1:#{port}/index.html" do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should be_empty }
  its(:stdout) { should match(/<!DOCTYPE/) }
end
