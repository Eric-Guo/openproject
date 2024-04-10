# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: open_project.proto

require 'google/protobuf'
require 'google/protobuf/empty_pb'

# it's required bydelayed_job
module Proto
  module OpenProjectPb
  end
end

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("open_project.proto", :syntax => :proto3) do
    add_message "TemplateDataItem" do
      optional :value, :string, 1
      optional :color, :string, 2
    end
    add_message "MessageRequest" do
      optional :templateID, :string, 1
      map :data, :string, :message, 2, "TemplateDataItem"
      optional :url, :string, 3
      optional :toLogin, :string, 5
      optional :toUserID, :int64, 4
    end
    add_message "Result" do
      optional :code, :int64, 1
      optional :message, :string, 2
    end
    add_message "Template" do
      optional :title, :string, 1
      optional :templateID, :string, 2
      optional :body, :string, 3
      optional :trade, :string, 4
    end
    add_message "GetTemplateResp" do
      repeated :templates, :message, 1, "Template"
    end
    add_message "GetUserInfoByCodeReq" do
      optional :code, :string, 1
    end
    add_message "WorkerMessageReq" do
      optional :toUserID, :int64, 1
      optional :title, :string, 2
      optional :description, :string, 3
      optional :url, :string, 4
      optional :buttonText, :string, 5
    end
    add_message "ReportForm" do
      optional :ID, :int64, 1
      optional :ReportProjectID, :int64, 2
      optional :Type, :string, 3
      optional :Subject, :string, 4
      optional :Status, :string, 5
      optional :StartTime, :string, 6
      optional :EndTime, :string, 7
      optional :Duration, :string, 8
      optional :Remarks, :string, 9
      optional :ParentID, :int64, 10
    end
    add_message "GetPdfReq" do
      repeated :Data, :message, 1, "ReportForm"
      optional :Email, :string, 2
    end
    add_message "GetPdfResp" do
      optional :url, :string, 1
    end
  end
end

TemplateDataItem = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("TemplateDataItem").msgclass
MessageRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("MessageRequest").msgclass
Result = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Result").msgclass
Template = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Template").msgclass
GetTemplateResp = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("GetTemplateResp").msgclass
GetUserInfoByCodeReq = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("GetUserInfoByCodeReq").msgclass
WorkerMessageReq = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("WorkerMessageReq").msgclass
ReportForm = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("ReportForm").msgclass
GetPdfReq = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("GetPdfReq").msgclass
GetPdfResp = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("GetPdfResp").msgclass
