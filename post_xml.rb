require 'net/http'
require 'net/https'
require 'nokogiri'
require "uri"

module BSG
  # API documentation https://bsg.hk/developers/
	class Client
	    attr_accessor :login, :password, :sender

	    def initialize(login, password, sender: nil)
		    @login = login
		    @password = password
		    @sender = sender
	    end

		def send(text, options = {})
			to = options[:to]
			to = to.map(&:to_s).join(';') if to.is_a? Array
 
			msg_from = options[:sender] || sender


		 	payload = Nokogiri::XML::Builder.new do |xml|
			  	xml.request {
				    xml.message('type' => 'sms') {
				    	xml.sender { xml.cdata msg_from }
				        xml.text_ { xml.cdata text }
				        xml.abonent('phone' => to, 'number_sms' => '1')
			    	}
				    xml.security {
				    	xml.login('value' => @login)
				    	xml.password('value' => @password)
				    }
				}
			end

			uri = URI.parse('http://app.bsg.hk/xml')
			request = Net::HTTP::Post.new uri.path
			request.body = payload.to_xml
			request.content_type = 'text/xml'
			response = Net::HTTP.new(uri.host, uri.port).start { |http| http.request request }
			doc = Nokogiri::XML(response.body)
			print doc.xpath('//@id_sms').map(&:value)
		end
		def send_bulk(text, options = {})

			to = options[:to]
      		to = to.map(&:to_s) if to.is_a? Array
      		hash = Hash.new
			to.each_with_index {|item, index|
				hash[item] = index
			}
			destination = hash

			msg_from = options[:sender] || sender


		 	payload = Nokogiri::XML::Builder.new do |xml|
			  	xml.request {
				    xml.message('type' => 'sms') {
				    	xml.sender { xml.cdata msg_from }
				        xml.text_ { xml.cdata text }
				        destination.each do |key, value|
				        	xml.abonent('phone' => key, 'number_sms' => value)
				        end
			    	}
				    xml.security {
				    	xml.login('value' => @login)
				    	xml.password('value' => @password)
				    }
				}
			end
			uri = URI.parse('http://app.bsg.hk/xml')
			request = Net::HTTP::Post.new uri.path
			request.body = payload.to_xml
			request.content_type = 'text/xml'
			response = Net::HTTP.new(uri.host, uri.port).start { |http| http.request request }
			doc = Nokogiri::XML(response.body)
			print doc.xpath('//@id_sms').map(&:value)
		end

		def get_status(smscid)
			
			smscid = smscid.map(&:to_s).join(';') if smscid.is_a? Array
			      
			payload = Nokogiri::XML::Builder.new do |xml|
			    xml.request {
					xml.get_state {
					        xml.id_sms smscid
					}
					xml.security {
						xml.login('value' => @login)
						xml.password('value' => @password)
					}
				}
			end

			uri = URI.parse('http://app.bsg.hk/xml/stat')
			request = Net::HTTP::Post.new uri.path
			request.body = payload.to_xml
			request.content_type = 'text/xml'
			response = Net::HTTP.new(uri.host, uri.port).start { |http| http.request request }

			doc = Nokogiri::XML(response.body)
			a = doc.xpath('//response/state').map do |status|
				{ status.xpath('@id_sms').text => status.xpath('//state').text.downcase.to_sym }
			end
			print a

    	end

		def get_statuses(smscid)
			
			smscid = smscid.map(&:to_s) if smscid.is_a? Array
	        hash = Hash.new
			smscid.each_with_index {|item, index|
				hash[item] = index
			}
			state = hash
			      
			payload = Nokogiri::XML::Builder.new do |xml|
			    xml.request {
					xml.get_state {
						state.each do |key, value|
					        xml.id_sms key
					    end
					}
					xml.security {
						xml.login('value' => @login)
						xml.password('value' => @password)
					}
				}
			end

			uri = URI.parse('http://app.bsg.hk/xml/stat')
			request = Net::HTTP::Post.new uri.path
			request.body = payload.to_xml
			request.content_type = 'text/xml'
			response = Net::HTTP.new(uri.host, uri.port).start { |http| http.request request }

			doc = Nokogiri::XML(response.body)
			a = doc.xpath('//response/state').map do |status|
				{ status.xpath('@id_sms').text => status.xpath('//state').text.downcase.to_sym }
			end
			print a

    	end


	end
end
