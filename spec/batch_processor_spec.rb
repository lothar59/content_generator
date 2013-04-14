require_relative '../lib/batch_processor'

describe BatchProcessor do
  it 'should exit with status 0' do
    expect(BatchProcessor.new(taxonomy: "taxonomy.xml", content: "destinations.xml", output_dir: "dest").generate_destination_files).to eq 0 
  end
end