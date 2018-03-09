#!/usr/bin/env ruby

require 'rubygems'
require 'bundler'
Bundler.require(:default)

require 'ostruct'
require 'json'
require 'logger'
require 'base64'
require 'yaml'

logger = Logger.new(STDOUT)
secrets = YAML.safe_load(File.read('secrets.yml'))

credentials = Boton::API::Clients::UserCredentials.new(secrets['username'],
                                                       secrets['password'])
site = 'https://api.theboton.io/business/v1'
client = Boton::API::Clients::Business.new(credentials, site: site)

# retrieves address using google api
class AddressProvider
  def initialize(key)
    @key = key
  end

  def get(lat, lon)
    url = 'https://maps.googleapis.com/maps/api/geocode/json'\
          "?latlng=#{lon},#{lat}&key=#{@key}"
    response = Faraday.get(url)
    address = JSON.parse(response.body)
    address['results'][0]['formatted_address']
  end
end

vehicles = [
  '0d15799e-9948-4e49-b25a-5809db81065f',
  '22b75191-684c-47c8-b637-047d1d2c4cc4',
  '24d214fb-b133-475f-9307-bdc72aced486',
  '2b4eb1a3-60bc-4b47-8c58-65e8f91b0a49',
  '3a340f38-6ed1-4800-a361-7029413e7949',
  '4d004194-af93-4df4-856c-4025a1c93228',
  '52f549de-b2a2-4080-b3de-5ea4c1b9eb71',
  '6ff202ea-1b7a-4d11-bb8c-6b8d981a92ab',
  '71327e65-b7b8-4eb0-8edd-5de614b36bd5',
  '84fd6e26-1f44-4106-8fb4-a528a0af2f6f',
  '9138abae-b8a3-4951-b8aa-8c6e9dbd95f0',
  '94502fdf-1515-41fc-bdcd-b3c784ca6570',
  '99079f3d-fc47-4a80-b916-2857684934c3',
  'c62e0b3b-0378-4583-9cb3-56f88f3c2785',
  'cda48256-2324-47b1-be58-d681cdd9ca2d',
  'de38b50a-bdb7-4ae3-891b-2ce1f847d57c',
  'dfff0646-d5e4-4810-970c-8c454b1e5364',
  'fd05a657-d776-4257-8a8e-990d7ec57246',
  'ff5fa275-2be0-42ff-a666-abb4af7fa46d'
]

address_provider = AddressProvider.new(secrets['google_api_key'])

vehicles.each do |vehicle_id|
  logger.info "Processing vehicle #{vehicle_id}"
  client.trips.find(vehicle_id).each do |trip|
    next unless trip.start_location.empty? && trip.points.present? &&
                trip.points.length > 1
    logger.info "  -> Trip #{trip.id}"
    start_point = trip.points[0]
    end_point = trip.points[-1]
    logger.info "    * Start: #{start_point.latitude}, #{start_point.longitude}"
    logger.info "    * End: #{end_point.latitude}, #{end_point.longitude}"
    start_location = address_provider.get(start_point.longitude,
                                          start_point.latitude)
    end_location = address_provider.get(end_point.longitude, end_point.latitude)
    logger.info "    * Path: #{start_location} => #{end_location}"
    logger.info '    - Updating trip'
    client.trips.update(trip.id, vehicle_id: vehicle_id,
                                 start_location: start_location,
                                 end_location: end_location)
  end
end
