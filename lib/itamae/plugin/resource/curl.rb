require 'itamae/resource/file'

module Itamae
  module Plugin
    module Resource
      class Curl < ::Itamae::Resource::File
        ChecksumMismatch = Class.new(StandardError)

        define_attribute :source,   type: String, required: true
        define_attribute :checksum, type: String

        def pre_action
          case @current_action
          when :create, :edit
            attributes.exist = true
            download_file
          when :delete
            attributes.exist = false
          end
        end

        private

        def ensure_curl_available
          unless run_command('which curl', error: false).exit_status == 0
            fail '`curl` command is not available. Please install curl.'
          end
        end

        def validate_checksum
          checksum = run_specinfra(:get_file_sha256sum, @temppath).stdout.chomp

          unless attributes.checksum == checksum
            fail ChecksumMismatch, "Checksum on resource (#{checksum}) does not match checksum on content (#{attributes.checksum})"
          end
        end

        def download_file
          ensure_curl_available

          @temppath = ::File.join(runner.tmpdir, Time.now.to_f.to_s)

          run_command(['curl', '-o', @temppath, attributes.source])

          validate_checksum if attributes.checksum
        end
      end
    end
  end
end
