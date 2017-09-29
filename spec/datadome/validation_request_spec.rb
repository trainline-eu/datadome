# frozen_string_literal: true

require "spec_helper"

RSpec.describe Datadome::ValidationRequest do
  describe ".from_env" do
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

    subject { described_class.from_env(env) }

    context "considering `Accept` param" do
      it "retrieves it" do
        expect(subject["Accept"]).to eq("*/*")
      end

      it "limits it to 512 bytes" do
        env["HTTP_ACCEPT"] = "a" * 5000
        expect(subject["Accept"].length).to eq(512)
      end
    end

    context "considering `AcceptCharset` param" do
      it "retrieves it" do
        expect(subject["AcceptCharset"]).to eq("utf-8, iso-8859-1;q=0.5")
      end

      it "limits it to 128 bytes" do
        env["HTTP_ACCEPT_CHARSET"] = "a" * 5000
        expect(subject["AcceptCharset"].length).to eq(128)
      end
    end

    context "considering `AcceptEncoding` param" do
      it "retrieves it" do
        expect(subject["AcceptEncoding"]).to eq("gzip, deflate")
      end

      it "limits it to 128 bytes" do
        env["HTTP_ACCEPT_ENCODING"] = "a" * 5000
        expect(subject["AcceptEncoding"].length).to eq(128)
      end
    end

    context "considering `AcceptLanguage` param" do
      it "retrieves it" do
        expect(subject["AcceptLanguage"]).to eq("fr-FR,fr;q=0.8,en-US;q=0.6,en;q=0.4")
      end

      it "limits it to 256 bytes" do
        env["HTTP_ACCEPT_LANGUAGE"] = "a" * 5000
        expect(subject["AcceptLanguage"].length).to eq(256)
      end
    end

    context "considering `AuthorizationLen` param" do
      it "retrieves it" do
        env["HTTP_AUTHORIZATION"] = "Basic YWxhZGRpbjpvcGVuc2VzYW1l"
        expect(subject["AuthorizationLen"]).to eq(30)
      end

      it "handles no Authorization header" do
        env.delete("HTTP_AUTHORIZATION")
        expect(subject["AuthorizationLen"]).to eq(0)
      end
    end

    context "considering `CacheControl` param" do
      it "retrieves it" do
        expect(subject["CacheControl"]).to eq("no-cache, no-store, must-revalidate")
      end

      it "limits it to 512 bytes", pending: "unspecified yet" do
        env["HTTP_CACHE_CONTROL"] = "a" * 5000
        expect(subject["CacheControl"].length).to eq(512)
      end
    end

    context "considering `ClientID` param" do
      it "retrieves it" do
        expect(subject["ClientID"]).to eq("AHrlqAAAAAMA9RBP7xmrgZcAAAAAAA==")
      end

      it "limits it to 128 bytes" do
        env["HTTP_COOKIE"] = "datadome=#{"a" * 5000}"
        expect(subject["ClientID"].length).to eq(128)
      end
    end

    context "considering `Connection` param" do
      it "retrieves it" do
        expect(subject["Connection"]).to eq("keep-alive")
      end

      it "limits it to 512 bytes", pending: "unspecified yet" do
        env["HTTP_CONNECTION"] = "a" * 5000
        expect(subject["Connection"].length).to eq(512)
      end
    end

    context "considering `CookiesLen` param" do
      it "retrieves it" do
        expect(subject["CookiesLen"]).to eq(63)
      end

      it "handles no cookies" do
        env.delete("HTTP_COOKIE")
        expect(subject["CookiesLen"]).to eq(0)
      end
    end

    context "considering `HeadersList` param" do
      it "retrieves it" do
        expect(subject["HeadersList"]).to eq("host,connection,pragma,cache-control,accept,x-csrf-token,user-agent,x-requested-with,x-forwarded-for,origin,referer,accept-charset,accept-encoding,accept-language,cookie")
      end

      it "limits it to 512 bytes" do
        env["HTTP_#{"a" * 5000}"] = "foo"
        expect(subject["HeadersList"].length).to eq(512)
      end
    end

    context "considering `Host` param" do
      it "retrieves it" do
        expect(subject["Host"]).to eq("www.my-domain.com")
      end

      it "limits it to 512 bytes", pending: "unspecified yet" do
        env["HTTP_HOST"] = "a" * 5000
        expect(subject["Host"].length).to eq(512)
      end
    end

    context "considering `IP` param" do
      it "retrieves it" do
        expect(subject["IP"]).to eq("12.23.34.45")
      end
    end

    context "considering `Method` param" do
      it "retrieves it" do
        expect(subject["Method"]).to eq("GET")
      end
    end

    context "considering `Origin` param" do
      it "retrieves it" do
        expect(subject["Origin"]).to eq("www.my-origin-domain.com")
      end

      it "limits it to 512 bytes" do
        env["HTTP_ORIGIN"] = "a" * 5000
        expect(subject["Origin"].length).to eq(512)
      end
    end

    context "considering `Port` param" do
      it "retrieves it" do
        expect(subject["Port"]).to eq(80)
      end
    end

    context "considering `PostParamLen` param" do
      it "retrieves it" do
        expect(subject["PostParamLen"]).to eq(8)
      end

      it "handles no body" do
        env.delete("rack.input")
        expect(subject["PostParamLen"]).to eq(0)
      end
    end

    context "considering `Pragma` param" do
      it "retrieves it" do
        expect(subject["Pragma"]).to eq("no-cache")
      end

      it "limits it to 512 bytes", pending: "unspecified yet" do
        env["HTTP_PRAGMA"] = "a" * 5000
        expect(subject["Pragma"].length).to eq(512)
      end
    end

    context "considering `Protocol` param" do
      it "retrieves it" do
        expect(subject["Protocol"]).to eq("HTTP")
      end
    end

    context "considering `Referer` param" do
      it "retrieves it" do
        expect(subject["Referer"]).to eq("http://www.other-domain.com/other/path")
      end

      it "limits it to 1024 bytes" do
        env["HTTP_REFERER"] = "a" * 5000
        expect(subject["Referer"].length).to eq(1024)
      end
    end

    context "considering `Request` param" do
      it "retrieves it" do
        expect(subject["Request"]).to eq("/my/path?foo=bar&baz=1")
      end

      it "limits it to 2048 bytes" do
        env["ORIGINAL_FULLPATH"] = "a" * 5000
        expect(subject["Request"].length).to eq(2048)
      end
    end

    # context "considering `ServerHostname` param" do
    #   it "retrieves it" do
    #     expect(subject["ServerHostname"]).to eq("*/*")
    #   end

    #   it "limits it to 512 bytes" do
    #     env["HTTP_SERVERHOSTNAME"] = "a" * 5000
    #     expect(subject["ServerHostname"].length).to eq(512)
    #   end
    # end

    context "considering `TimeRequest` param" do
      context "when `X-Request-Start` header is present" do
        it "uses the header's value" do
          env["HTTP_X_REQUEST_START"] = "t=1502197900123456"
          expect(subject["TimeRequest"]).to eq(1_502_197_900_123_456)
        end
      end

      it "uses now" do
        Timecop.freeze(Time.at(1_502_197_974, 123_456)) do
          expect(subject["TimeRequest"]).to eq(1_502_197_974_123_456)
        end
      end
    end

    context "considering `UserAgent` param" do
      it "retrieves it" do
        expect(subject["UserAgent"]).to eq("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36")
      end

      it "limits it to 768 bytes" do
        env["HTTP_USER_AGENT"] = "a" * 5000
        expect(subject["UserAgent"].length).to eq(768)
      end
    end

    # typo in API: should be XForwardedForIP
    context "considering `XForwaredForIP` param" do
      it "retrieves it" do
        expect(subject["XForwaredForIP"]).to eq("12.23.34.45")
      end

      it "limits it to 512 bytes" do
        env["HTTP_X_FORWARDED_FOR"] = "a" * 5000
        expect(subject["XForwaredForIP"].length).to eq(512)
      end
    end

    # typo in API: should be XRequestedWith
    context "considering `X-Requested-With` param" do
      it "retrieves it" do
        expect(subject["X-Requested-With"]).to eq("XMLHttpRequest")
      end

      it "limits it to 128 bytes" do
        env["HTTP_X_REQUESTED_WITH"] = "a" * 5000
        expect(subject["X-Requested-With"].length).to eq(128)
      end
    end
  end
end
