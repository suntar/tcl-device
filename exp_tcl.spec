Name:         exp_tcl
Version:      1.0
Release:      alt1

Summary:      TCL packages for my experimental computer
Group:        System
URL:          https://github.com/slazav/exp_tcl
License:      GPL

Packager:     Vladislav Zavjalov <slazav@altlinux.org>

Source:       %name-%version.tar

%description
TCL packages for my experimental computer

%prep
%setup -q

%build
# build and install tcl packages
for n in Graphene\
         GrapheneMonitor\
         ParseOptions-1.0\
         Prectime-1.1\
         Daemon\
         Locking-1.1\
         xBLT\
         GPIB\
         Device; do
  [ ! -s "$n/Makefile" ] || make -C $n
  mkdir -p %buildroot/%_tcldatadir/$n/
  mkdir -p %buildroot/%_libdir/tcl/
  install -m644 $n/*.tcl %buildroot/%_tcldatadir/$n/ ||:
  install -m644 $n/*.so  %buildroot/%_libdir/tcl/ ||:
  sed -i -e 's|%%LIB_DIR%%|%_libdir/tcl/|' %buildroot/%_tcldatadir/$n/pkgIndex.tcl
done


%files
%_tcldatadir/*
%_libdir/tcl/*

%changelog
