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
         DeviceRole\
         ; do
  mkdir -p %buildroot/%_tcldatadir/$n/
  for f in $n/*; do
    if [ -d $f -o ${f%%.tcl} != $f ]; then
      cp -r $f %buildroot/%_tcldatadir/$n/
    fi
  done
done
mkdir -p %buildroot/%_bindir/
install -m755 bin/*  %buildroot/%_bindir/ ||:

%files
%_tcldatadir/*
%_bindir/*

%changelog
