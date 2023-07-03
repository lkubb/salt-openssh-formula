# frozen_string_literal: true

control 'openssh.package.install' do
  title 'The required package should be installed'

  package_name = 'openssh'

  describe package(package_name) do
    it { should be_installed }
  end
end
