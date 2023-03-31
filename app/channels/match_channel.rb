class MatchChannel < ApplicationCable::Channel
  def subscribed
    # Called when the consumer has successfully
    # become a subscriber to this channel.
    puts "Subscribed to MatchChannel"
  end
end