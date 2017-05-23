Name:         exp_tcl
Version:      1.0
Release:      alt1

Summary:      TCL packages for my experimental computer
Group:        System
URL:          https://github.com/slazav/exp_tcl
License:      GPL
BuildArch:    noarch
Packager:     Vladislav Zavjalov <slazav@altlinux.org>

Source:       %name-%version.tar

%description
TCL packages for my experimental computer

%prep
%setup -q

%build
# build and install tcl packages
for n in \
         GrapheneMonitor\
         GrapheneViewer\
         ParseOptions-2.0\
         Device\
         ; do
  mkdir -p %buildroot/%_tcldatadir/$n/
  install -m644 $n/*.tcl %buildroot/%_tcldatadir/$n/ ||:
done
mkdir -p %buildroot/%_bindir/
install -m755 bin/*  %buildroot/%_bindir/ ||:


%files
%_tcldatadir/*
%_bindir/*

%changelog
