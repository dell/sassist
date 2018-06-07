Name:		sassist
Version:	0.8.0
Release:	1%{?dist}
Summary:	Dell SupportAssist log collector

Group:		System Environment/Daemons
License:	MIT
URL:		http://www.dell.com/en-us/work/learn/supportassist
Source0:	sassist-%{version}.tar.gz

%if 0%{?suse_version}
Requires: supportutils
%else
Requires: sos
Requires: systemd-units
Requires(post): systemd-units
Requires(postun): systemd-units
%endif
Requires: freeipmi
Requires: systemd
Requires: zip

BuildArch: noarch
%{?systemd_requires}

%description
Dell SupportAssist log collector for Linux.

%prep
%setup -q -n sassist-%{version}

%build

%install
rm -rf -- "%{buildroot}"

mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_unitdir}

install -p -m555 sassist.sh %{buildroot}%{_bindir}
install -p -m644 systemd/sassist.service %{buildroot}%{_unitdir}
install -p -m644 systemd/sassist-collect.service %{buildroot}%{_unitdir}
install -p -m644 systemd/media-iDRAC_NATOSC.mount %{buildroot}%{_unitdir}

%clean
rm -rf -- "%{buildroot}"

%files
%defattr(-,root,root,-)
%doc COPYING
%{_bindir}/sassist.sh
%{_unitdir}/sassist.service
%{_unitdir}/sassist-collect.service
%{_unitdir}/media-iDRAC_NATOSC.mount

%post
%systemd_post sassist.service

%preun
%systemd_preun sassist.service

%postun
%systemd_postun_with_restart sassist.service

%changelog
* Mon Apr 02 2018 Charles Rose <charles_rose@dell.com> - 0.8.0
- add support for supportconfig

* Mon Apr 02 2018 Charles Rose <charles_rose@dell.com> - 0.7.1
- support multi-distro

* Mon Aug 28 2017 Charles Rose <charles_rose@dell.com> - 0.7.0-1
- first RPM release
