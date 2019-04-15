%define teaname Device
%define major 1.0

Name:         tcl-device
Version:      %major
Release:      alt1

Summary:      Device library
Group:        System
URL:          https://github.com/slazav/tcl-device
License:      GPL
BuildArch:    noarch
Packager:     Vladislav Zavjalov <slazav@altlinux.org>

Source:       %name-%version.tar

%description
tcl_device -- Device library
%prep
%setup -q

%install
mkdir -p %buildroot/%_tcldatadir/%teaname
install -m644 *.tcl %buildroot/%_tcldatadir/%teaname

mkdir -p %buildroot/%_bindir/
install -m755 bin/*  %buildroot/%_bindir/ ||:

%files
%_tcldatadir/*
%_bindir/*

%changelog
