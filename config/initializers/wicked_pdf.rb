WickedPdf.configure do |config|
  config.exe_path = if ENV['WKHTMLTOPDF_PATH']
                      ENV['WKHTMLTOPDF_PATH']
                    elsif File.exist?('/app/bin/wkhtmltopdf')
                      '/app/bin/wkhtmltopdf'
                    else
                      Gem.bin_path('wkhtmltopdf-binary', 'wkhtmltopdf')
                    end
end
