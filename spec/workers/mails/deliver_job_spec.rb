require "rails_helper"

RSpec.describe Mails::DeliverJob do
  describe "#handle_ssl_read_error" do
    subject(:handle_error) { job.send(:handle_ssl_read_error, error) }

    let(:job) { described_class.new }
    let(:error) { OpenSSL::SSL::SSLError.new(message) }

    before do
      allow(job).to receive(:executions).and_return(executions)
    end

    context "when the error message matches and executions are below the max" do
      let(:executions) { described_class::SSL_READ_MAX_ATTEMPTS - 1 }
      let(:message) { described_class::SSL_READ_RETRY_MESSAGE }

      it "retries the job with the configured delay" do
        expect(job).to receive(:retry_job).with(wait: described_class::SSL_READ_RETRY_DELAY)
        handle_error
      end
    end

    context "when executions already reached the max" do
      let(:executions) { described_class::SSL_READ_MAX_ATTEMPTS }
      let(:message) { described_class::SSL_READ_RETRY_MESSAGE }

      it "re-raises the error" do
        expect { handle_error }.to raise_error(OpenSSL::SSL::SSLError)
      end
    end

    context "when the error message does not match" do
      let(:executions) { 1 }
      let(:message) { "SSL_connect: connection reset" }

      it "re-raises the error" do
        expect { handle_error }.to raise_error(OpenSSL::SSL::SSLError)
      end
    end
  end
end
