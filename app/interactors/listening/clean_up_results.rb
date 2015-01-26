module Listening
  class CleanUpResults
    include Interactor

    def call
      clean = []

      context._results.aggregations.minutes.buckets.each do |b|
        ts = Time.at(b['key'] / 1000)
        obj = Hashie::Mash.new time:ts.utc, streams:{}, rewind:{}

        b.stream.buckets.each do |sb|
          obj.streams[ sb['key'] ] = { requests:sb.doc_count, duration:sb.duration.value }
        end

        b.rewind.buckets.each do |sr|
          obj.rewind[ sr['key'] ] = { duration:sr.duration.value }
        end

        clean << obj
      end

      context.results = clean
    end
  end
end