WickedPdf.configure do |config|
  config.exe_path = ENV.fetch('WKHTMLTOPDF_PATH') {
    ['/app/bin/wkhtmltopdf', '/usr/local/bin/wkhtmltopdf', `which wkhtmltopdf`.strip].find { |p| File.exist?(p) } ||
      (Gem.bin_path('wkhtmltopdf-binary', 'wkhtmltopdf') rescue '/usr/local/bin/wkhtmltopdf')
  }
end
