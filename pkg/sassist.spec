Name:		sassist
Version:	0.8.1
Release:	1%{?dist}
Summary:	Dell SupportAssist log collector

License:	MIT
URL:		http://www.dell.com/en-us/work/learn/supportassist
Source0:	https://github.com/dell/sassist/archive/%{version}/%{name}-%{version}.tar.gz

BuildRequires:	systemd

%if 0%{?suse_version}
Requires: supportutils
%else
Requires: sos
%endif
Requires: freeipmi
Requires: zip

BuildArch: noarch
%{?systemd_requires}

%description
Dell SupportAssist log collector for Linux.

%prep
%setup -q -n %{name}-%{version}

%build

%install
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_unitdir}

install -p -m555 src/sassist.sh %{buildroot}%{_bindir}
install -p -m644 src/systemd/sassist.service %{buildroot}%{_unitdir}
install -p -m644 src/systemd/sassist-collect.service %{buildroot}%{_unitdir}
install -p -m644 src/systemd/media-iDRAC_NATOSC.mount %{buildroot}%{_unitdir}

%files
%license COPYING
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
* Thu Jun 14 2018 Charles Rose <charles_rose@dell.com> - 0.8.1
- add dependency on zip. fix temp dir creation bug

* Mon Apr 02 2018 Charles Rose <charles_rose@dell.com> - 0.8.0
- add support for supportconfig

* Mon Apr 02 2018 Charles Rose <charles_rose@dell.com> - 0.7.1
- support multi-distro

* Mon Aug 28 2017 Charles Rose <charles_rose@dell.com> - 0.7.0-1
- first RPM release
