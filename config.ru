require 'rack/contrib/nested_params'
require 'rack/contrib/post_body_content_type_parser'
require 'lib/api'

use Rack::NestedParams
use Rack::PostBodyContentTypeParser

run API::App
