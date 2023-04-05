# frozen_string_literal: true

require "spec_helper"

RSpec.describe Datadome::Inquirer do
  let(:env) do
    {
      "SERVER_SOFTWARE" => "thin 1.7.2 codename Bachmanity",
      "SERVER_NAME" => "www.my-domain.com",
      "rack.input" => StringIO.new("the body"),
      "rack.version" => [1, 0],
      # "rack.errors"=>#<IO:<STDERR>>,
      "rack.multithread" => false,
      "rack.multiprocess" => false,
      "rack.run_once" => false,
      "REQUEST_METHOD" => "GET",
      "REQUEST_PATH" => "/my/path",
      "PATH_INFO" => "/my/path",
      "QUERY_STRING" => "foo=bar&baz=1",
      "REQUEST_URI" => "/my/path?foo=bar&baz=1",
      "HTTP_VERSION" => "HTTP/1.1",
      "HTTP_HOST" => "www.my-domain.com",
      "HTTP_CONNECTION" => "keep-alive",
      "HTTP_PRAGMA" => "no-cache",
      "HTTP_CACHE_CONTROL" => "no-cache, no-store, must-revalidate",
      "HTTP_ACCEPT" => "*/*",
      "HTTP_X_CSRF_TOKEN" => "p8NNwjcp0NBxO7hf5Y4jj10alFvIuE6qCHxGbz4tvNI3FHjZMutWhOJodqgneFKt9cSs1pRNq6Tbe7t1MqqYmA==",
      "HTTP_USER_AGENT" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36",
      "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest",
      "HTTP_X_FORWARDED_FOR" => "12.23.34.45",
      "HTTP_ORIGIN" => "www.my-origin-domain.com",
      "HTTP_REFERER" => "http://www.other-domain.com/other/path",
      "HTTP_ACCEPT_CHARSET" => "utf-8, iso-8859-1;q=0.5",
      "HTTP_ACCEPT_ENCODING" => "gzip, deflate",
      "HTTP_ACCEPT_LANGUAGE" => "fr-FR,fr;q=0.8,en-US;q=0.6,en;q=0.4",
      "HTTP_COOKIE" => "foo=bar; datadome=AHrlqAAAAAMA9RBP7xmrgZcAAAAAAA%3D%3D; baz=bar",
      "GATEWAY_INTERFACE" => "CGI/1.2",
      "SERVER_PORT" => "80",
      "SERVER_PROTOCOL" => "HTTP/1.1",
      "rack.url_scheme" => "http",
      "SCRIPT_NAME" => "",
      "REMOTE_ADDR" => "192.168.1.1",
      "ORIGINAL_FULLPATH" => "/my/path?foo=bar&baz=1",
      "ORIGINAL_SCRIPT_NAME" => "",
    }
  end

  let(:exclude_matchers) { [] }
  let(:include_matchers) { [] }
  let(:monitor_mode) { false }
  let(:intercept_matchers) { [] }
  let(:expose_headers) { false }

  subject { described_class.new(env, exclude_matchers: exclude_matchers, include_matchers: include_matchers, monitor_mode: monitor_mode, intercept_matchers: intercept_matchers, expose_headers: expose_headers) }

  describe "#ignore?" do
    context "without matchers" do
      it "returns false" do
        expect(subject.ignore?).to eq(false)
      end
    end

    context "with an exclude matcher" do
      let(:exclude_matchers) {
        [
          ->(request) { request.host == "www.my-domain.com" },
        ]
      }

      it "calls matchers with right parameters" do
        expect(exclude_matchers.first).to receive(:call).once

        subject.ignore?
      end

      it "returns true when the exclude matcher matches" do
        env["HTTP_HOST"] = "www.my-domain.com"
        expect(subject.ignore?).to eq(true)
      end

      it "returns false when the exclude matcher does not match" do
        env["HTTP_HOST"] = "www.other-domain.com"
        expect(subject.ignore?).to eq(false)
      end
    end

    context "with an include matcher" do
      let(:include_matchers) {
        [
          ->(request) { request.host == "www.my-domain.com" },
        ]
      }

      it "calls matchers with right parameters" do
        expect(include_matchers.first).to receive(:call).once

        subject.ignore?
      end

      it "returns false when the include matcher matches" do
        env["HTTP_HOST"] = "www.my-domain.com"
        expect(subject.ignore?).to eq(false)
      end

      it "returns true when the include matcher does not match" do
        env["HTTP_HOST"] = "www.other-domain.com"
        expect(subject.ignore?).to eq(true)
      end
    end

    context "with two include matchers" do
      let(:include_matchers) {
        [
          ->(request) { request.host == "www.my-domain.com" },
          ->(request) { request.path =~ %r{^/my} },
        ]
      }

      it "returns false when the first include matcher matches and the second include matcher matches" do
        env["HTTP_HOST"] = "www.my-domain.com"
        env["PATH_INFO"] = "/my/path"
        expect(subject.ignore?).to eq(false)
      end

      it "returns false when the first include matcher matches and the second include matcher does not match" do
        env["HTTP_HOST"] = "www.my-domain.com"
        env["PATH_INFO"] = "/other/path"
        expect(subject.ignore?).to eq(false)
      end

      it "returns false when the first include matcher does not match and the second include matcher matches" do
        env["HTTP_HOST"] = "www.other-domain.com"
        env["PATH_INFO"] = "/my/path"
        expect(subject.ignore?).to eq(false)
      end

      it "returns true when the first include matcher does not match and the second include matcher does not match" do
        env["HTTP_HOST"] = "www.other-domain.com"
        env["PATH_INFO"] = "/other/path"
        expect(subject.ignore?).to eq(true)
      end
    end

    context "with an exclude matchers and an include matchers" do
      let(:exclude_matchers) {
        [
          ->(request) { request.host =~ /^admin\./ },
        ]
      }
      let(:include_matchers) {
        [
          ->(request) { request.host =~ /\.my-domain.com$/ },
        ]
      }

      it "returns true when the exclude matcher matches and the include matcher matches" do
        env["HTTP_HOST"] = "admin.my-domain.com"
        expect(subject.ignore?).to eq(true)
      end

      it "returns true when the exclude matcher matches and the include matcher does not match" do
        env["HTTP_HOST"] = "admin.other-domain.com"
        expect(subject.ignore?).to eq(true)
      end

      it "returns false when the exclude matcher does not match and the include matcher matches" do
        env["HTTP_HOST"] = "www.my-domain.com"
        expect(subject.ignore?).to eq(false)
      end

      it "returns true when the exclude matcher does not match and the include matcher does not match" do
        env["HTTP_HOST"] = "www.other-domain.com"
        expect(subject.ignore?).to eq(true)
      end
    end
  end

  describe "#intercept?" do
    context 'monitor mode is disabled' do
      let(:monitor_mode) { false }

      it "returns true" do
        validation_response = instance_double("Datadome::ValidationResponse", pass: false, redirect: false)
        subject.instance_variable_set('@validation_response', validation_response)

        expect(subject.intercept?).to eq(true)
      end
    end

    context "monitor mode is enabled" do
      let(:monitor_mode) { true }
      let(:intercept_matchers) { [->(env) { /Webapp/.match(env['HTTP_USER_AGENT']) }]  }

      context "when a matcher returns true and when request is flagged as coming from a bot" do
        it "returns true" do
          env['HTTP_USER_AGENT'] = "Webapp"
          validation_response = instance_double("Datadome::ValidationResponse", pass: false, redirect: false)
          subject.instance_variable_set('@validation_response', validation_response)

          expect(subject.intercept?).to eq(true)
        end
      end

      context "when all matchers return false and when request is flagged as coming from a bot" do
        it "returns false" do
          env['HTTP_USER_AGENT'] = "Mweb"
          validation_response = instance_double("Datadome::ValidationResponse", pass: false, redirect: false)
          subject.instance_variable_set('@validation_response', validation_response)

          expect(subject.intercept?).to eq(false)
        end
      end
    end
  end

  describe "#enriching" do
      let(:response_headers) do
        {
          "X-DataDome"=>"protected",
          "Set-Cookie"=>"datadome=QwHWxE4aQ8zM7e0O4IFsNEl3dbRYJdHvgxk4hqYQr-BJK3uUzi6CtLOiOvGywxu1KY_q8TrHyUJV_j_KppDbreHWdcMQL.GM2RfxP_vf4c; Max-Age=31536000; Domain=.trainline.eu; Path=/; Secure; SameSite=Lax",
        }
      end
      let(:request_headers) do
        {
          "X-DataDomeResponse"=>"200"
        }
      end
      let(:timeout) { false }

      before do
        subject.instance_variable_set('@inquiry_duration', 0.2)
        subject.instance_variable_set(
          '@validation_response',
          instance_double("Datadome::ValidationResponse", request_headers: request_headers, response_headers: response_headers, timeout: timeout),
        )
      end

    context "with expose_headers option enabled" do
      let(:expose_headers) { true }

      it "adds enriched headers to the response headers" do
        _status, headers, _response = subject.enriching { [200, {}, nil] }

        expect(headers.keys).to include(*request_headers.keys.map(&:downcase), *response_headers.keys.map(&:downcase))
      end

      context "with a timeout" do
        let(:timeout) { true }

        it "returns -1 as response time" do
          _status, headers, _response = subject.enriching { [200, {}, nil] }

          expect(headers["X-DataDomeResponseTime"]).to eq(-1)
        end
      end
    end

    context "with expose_headers option disabled" do
      let(:expose_headers) { false }

      it "does not add enriched headers to the response headers" do
        _status, headers, _response = subject.enriching { [200, {}, nil] }

        expect(headers.keys).to include(*response_headers.keys.map(&:downcase))
      end
    end
  end
end
