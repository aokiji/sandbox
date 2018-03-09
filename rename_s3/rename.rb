#!/usr/bin/env ruby
# frozen_string_literal: true

require 'aws-sdk-s3'
require 'uri'

bad_file_regex = %r{[^\w\-.\/\(\)]}
bucket_name = 'b4-dms-production'
prefix = 'galleries/attachments'

def object_callback(s3, bucket, object)
  new_name = object.key.sub(%r{/t([^/]+)$}, '/tgt_\1')
  puts "Renaming #{object.key} to #{new_name}"
  s3.copy_object(bucket: bucket,
                 copy_source: URI.encode("/#{bucket}/#{object.key}"),
                 key: new_name)
  s3.put_object_acl(bucket: bucket, acl: 'public-read', key: new_name)
end

s3 = Aws::S3::Client.new(profile: 'trive')
resp = s3.list_objects_v2(bucket: bucket_name,
                          prefix: prefix)
response_counter = 1
while resp.is_truncated
  STDERR.puts "Got response #{response_counter}"
  bad_files = resp.contents.select do |object|
    object.key =~ bad_file_regex
  end

  bad_files.each do |object|
    object_callback s3, bucket_name, object
  end

  response_counter += 1
  resp = s3.list_objects_v2(bucket: bucket_name,
                            prefix: prefix,
                            continuation_token: resp.next_continuation_token)
end
