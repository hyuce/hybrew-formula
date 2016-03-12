class Vtk < Formula
  homepage "http://www.vtk.org"
  url "http://www.vtk.org/files/release/7.0/VTK-7.0.0.tar.gz"
  mirror "https://fossies.org/linux/misc/VTK-7.0.0.tar.gz"
  sha256 "78a990a15ead79cdc752e86b83cfab7dbf5b7ef51ba409db02570dbdd9ec32c3"

  head "https://github.com/Kitware/VTK.git"

  bottle do
    revision 1
    sha256 "f5370ca4b94383438348f44a51a1756ad6f3b9f8dae7da395c476d05956befbf" => :el_capitan
    sha256 "30b6b50bbf8babb49da1e924aeaaa598a4381b55e46db3aa27ac2bf2ecf2e7e2" => :yosemite
    sha256 "81d1c035f77a95ecf6e3062a03907d5ebbedcfe3e55d6513088f306204a907d0" => :mavericks
  end

  deprecated_option "examples" => "with-examples"
  deprecated_option "qt-extern" => "with-qt-extern"
  deprecated_option "tcl" => "with-tcl"
  deprecated_option "remove-legacy" => "without-legacy"
  deprecated_option "dicom" => "with-dicom"
  deprecated_option "ffmpeg" => "with-ffmepg"
  deprecated_option "addon" => "with-addon"
  
  option :cxx11
  option "with-examples",   "Compile and install various examples"
  option "with-qt-extern",  "Enable Qt4 extension via non-Homebrew external Qt4"
  option "with-tcl",        "Enable Tcl wrapping of VTK classes"
  option "with-matplotlib", "Enable matplotlib support"
  option "without-legacy",  "Disable legacy APIs"
  option "without-python",  "Build without python2 support"
  option "with-dicom",      "Request Building vtkDICOM"
  option "with-ffmpeg",     "Request Building vtkIOFFMPEG"
  option "with-addon",      "Request Building vtkAddon" 

  depends_on "cmake" => :build
  depends_on :x11 => :optional
  depends_on "qt" => :optional
  depends_on "qt5" => :optional

  depends_on :python => :recommended if MacOS.version <= :snow_leopard
  depends_on :python3 => :optional

  depends_on "boost" => :recommended
  depends_on "fontconfig" => :recommended
  depends_on "hdf5" => :recommended
  depends_on "jpeg" => :recommended
  depends_on "libpng" => :recommended
  depends_on "libtiff" => :recommended
  depends_on "matplotlib" => :python if build.with?("matplotlib") && build.with?("python")
  depends_on "ffmpeg" => :optional
  
  # If --with-qt and --with-python, then we automatically use PyQt, too!
  if build.with? "python"
    if build.with? "qt"
      depends_on "sip"
      depends_on "pyqt"
    elsif build.with? "qt5"
      depends_on "sip"
      depends_on "pyqt5" => ["with-python", "without-python3"]
    end
  end

  if build.with? "python3"
    if build.with? "qt"
      depends_on "sip" => ["with-python3", "without-python"]
      depends_on "pyqt" => ["with-python3", "without-python" ]
    elsif build.with? "qt5"
      depends_on "sip"   => ["with-python3", "without-python"]
      depends_on "pyqt5"
    end
  end

  def install
    args = std_cmake_args + %W[
      -DVTK_REQUIRED_OBJCXX_FLAGS=''
      -DBUILD_SHARED_LIBS=ON
      -DCMAKE_INSTALL_RPATH:STRING=#{lib}
      -DCMAKE_INSTALL_NAME_DIR:STRING=#{lib}
      -DVTK_USE_SYSTEM_EXPAT=ON
      -DVTK_USE_SYSTEM_LIBXML2=ON
      -DVTK_USE_SYSTEM_ZLIB=ON
    ]

    args << "-DBUILD_EXAMPLES=" + ((build.with? "examples") ? "ON" : "OFF")

    if build.with? "examples"
      args << "-DBUILD_TESTING=ON"
    else
      args << "-DBUILD_TESTING=OFF"
    end

    if build.with?("qt") || build.with?("qt5") || build.with?("qt-extern")
      args << "-DVTK_QT_VERSION:STRING=5" if build.with? "qt5"
      args << "-DVTK_Group_Qt=ON"
    end

    args << "-DVTK_WRAP_TCL=ON" if build.with? "tcl"

    # Cocoa for everything except x11
    if build.with? "x11"
      args << "-DVTK_USE_COCOA=OFF"
      args << "-DVTK_USE_X=ON"
    else
      args << "-DVTK_USE_COCOA=ON"
    end

    unless MacOS::CLT.installed?
      # We are facing an Xcode-only installation, and we have to keep
      # vtk from using its internal Tk headers (that differ from OSX's).
      args << "-DTK_INCLUDE_PATH:PATH=#{MacOS.sdk_path}/System/Library/Frameworks/Tk.framework/Headers"
      args << "-DTK_INTERNAL_PATH:PATH=#{MacOS.sdk_path}/System/Library/Frameworks/Tk.framework/Headers/tk-private"
    end

    args << "-DModule_vtkInfovisBoost=ON" << "-DModule_vtkInfovisBoostGraphAlgorithms=ON" if build.with? "boost"
    args << "-DModule_vtkRenderingFreeTypeFontConfig=ON" if build.with? "fontconfig"
    args << "-DVTK_USE_SYSTEM_HDF5=ON" if build.with? "hdf5"
    args << "-DVTK_USE_SYSTEM_JPEG=ON" if build.with? "jpeg"
    args << "-DVTK_USE_SYSTEM_PNG=ON" if build.with? "libpng"
    args << "-DVTK_USE_SYSTEM_TIFF=ON" if build.with? "libtiff"
    args << "-DModule_vtkRenderingMatplotlib=ON" if build.with? "matplotlib"
    args << "-DVTK_LEGACY_REMOVE=ON" if build.without? "legacy"

    ENV.cxx11 if build.cxx11?

    mkdir "build" do
      if build.with?("python") && build.without?("python3")
        args << "-DVTK_WRAP_PYTHON=ON"
        # CMake picks up the system"s python dylib, even if we have a brewed one.
        args << "-DPYTHON_LIBRARY='#{`python-config --prefix`.chomp}/lib/libpython2.7.dylib'"
        # Set the prefix for the python bindings to the Cellar
        args << "-DVTK_INSTALL_PYTHON_MODULE_DIR='#{lib}/python2.7/site-packages'"
      elsif build.without?("python") && build.with?("python3")
        args << "-DVTK_WRAP_PYTHON=ON"
        args << "-DPYTHON_EXECUTABLE=/usr/local/bin/python3"
        args << "-DPYTHON_INCLUDE_DIR='#{`python3-config --prefix`.chomp}/include/python3.5m'"
        # CMake picks up the system"s python dylib, even if we have a brewed one.
        args << "-DPYTHON_LIBRARY='#{`python3-config --prefix`.chomp}/lib/libpython3.5m.dylib'"
        # Set the prefix for the python bindings to the Cellar
        args << "-DVTK_INSTALL_PYTHON_MODULE_DIR='#{lib}/python3.5m/site-packages'"
      elsif build.with?("python3") && build.with?("python")
        # Does not currenly support building both python 2 and 3 versions
         odie "VTK: Does not currently support building both python 2 and 3 wrappers"
      end

      if build.with?("qt") || build.with?("qt5")
        args << "-DVTK_WRAP_PYTHON_SIP=ON"
        args << "-DSIP_PYQT_DIR='#{Formula["pyqt"].opt_share}/sip'" if build.with? "qt"
        args << "-DSIP_PYQT_DIR='#{Formula["pyqt5"].opt_share}/sip'" if build.with? "qt5"
      end

      if build.with? "dicom"
        args << "-DBUILD_DICOM_PROGRAMS=ON"
      end
 
      if build.with? "ffmpeg"
        args << "-DModule_vtkIOFFMPEG=ON"
      end
 
      if build.with? "addon"
        args << "-DModule_vtkAddon=ON"
      end

      args << ".."
      system "cmake", *args
      system "make"
      system "make", "install"
    end

    (share+"vtk").install "Examples" if build.with? "examples"
  end

  def caveats
    s = ""
    s += <<-EOS.undent
        Even without the --with-qt option, you can display native VTK render windows
        from python. Alternatively, you can integrate the RenderWindowInteractor
        in PyQt, PySide, Tk or Wx at runtime. Read more:
            import vtk.qt4; help(vtk.qt4) or import vtk.wx; help(vtk.wx)

    EOS

    if build.with? "examples"
      s += <<-EOS.undent

        The scripting examples are stored in #{HOMEBREW_PREFIX}/share/vtk

      EOS
    end
    s.empty? ? nil : s
  end
    
    if build.head? 
       then 
       patch :DATA
       end
end

__END__
diff --git a/IO/FFMPEG/vtkFFMPEGWriter.cxx b/IO/FFMPEG/vtkFFMPEGWriter.cxx
index d3fd421..294b421 100644
--- a/IO/FFMPEG/vtkFFMPEGWriter.cxx
+++ b/IO/FFMPEG/vtkFFMPEGWriter.cxx
@@ -191,11 +191,11 @@ int vtkFFMPEGWriterInternal::Start()
   c->height = this->Dim[1];
   if (this->Writer->GetCompression())
     {
-    c->pix_fmt = PIX_FMT_YUVJ422P;
+    c->pix_fmt = AV_PIX_FMT_YUVJ422P;
     }
   else
     {
-    c->pix_fmt = PIX_FMT_BGR24;
+    c->pix_fmt = AV_PIX_FMT_BGR24;
     }
 
   //to do playback at actual recorded rate, this will need more work see also below
@@ -274,13 +274,13 @@ int vtkFFMPEGWriterInternal::Start()
 #endif
 
   //for the output of the writer's input...
-  this->rgbInput = avcodec_alloc_frame();
+  this->rgbInput = av_frame_alloc();
   if (!this->rgbInput)
     {
     vtkGenericWarningMacro (<< "Could not make rgbInput avframe." );
     return 0;
     }
-  int RGBsize = avpicture_get_size(PIX_FMT_RGB24, c->width, c->height);
+  int RGBsize = avpicture_get_size(AV_PIX_FMT_RGB24, c->width, c->height);
   unsigned char *rgb = (unsigned char *)av_malloc(sizeof(unsigned char) * RGBsize);
   if (!rgb)
     {
@@ -288,10 +288,10 @@ int vtkFFMPEGWriterInternal::Start()
     return 0;
     }
   //The rgb buffer should get deleted when this->rgbInput is.
-  avpicture_fill((AVPicture *)this->rgbInput, rgb, PIX_FMT_RGB24, c->width, c->height);
+  avpicture_fill((AVPicture *)this->rgbInput, rgb, AV_PIX_FMT_RGB24, c->width, c->height);
 
   //and for the output to the codec's input.
-  this->yuvOutput = avcodec_alloc_frame();
+  this->yuvOutput = av_frame_alloc();
   if (!this->yuvOutput)
     {
     vtkGenericWarningMacro (<< "Could not make yuvOutput avframe." );
@@ -349,12 +349,12 @@ int vtkFFMPEGWriterInternal::Write(vtkImageData *id)
   //convert that to YUV for input to the codec
 #ifdef VTK_FFMPEG_HAS_IMG_CONVERT
   img_convert((AVPicture *)this->yuvOutput, cc->pix_fmt,
-              (AVPicture *)this->rgbInput, PIX_FMT_RGB24,
+              (AVPicture *)this->rgbInput, AV_PIX_FMT_RGB24,
               cc->width, cc->height);
 #else
   //convert that to YUV for input to the codec
   SwsContext* convert_ctx = sws_getContext(
-    cc->width, cc->height, PIX_FMT_RGB24,
+    cc->width, cc->height, AV_PIX_FMT_RGB24,
     cc->width, cc->height, cc->pix_fmt,
     SWS_BICUBIC, NULL, NULL, NULL);
