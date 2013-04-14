require_relative '../lib/batch_processor'

describe BatchProcessor do
  before do
    @bp = BatchProcessor.new(taxonomy: "taxonomy.xml", content: "destinations.xml", output_dir: "dest")
  end
  
  it 'should exit with status 0' do
    expect(@bp.generate_destination_files).to eq 0   
  end

  # it 'should return true' do 
  #   @bp.stub(:create_output_dir).and_return(true)
  #   @bp.stub(:copy_static_files).and_return(true)
  #   @bp.stub(:move_in_directory).and_return(true)
  #   @bp.stub(:get_root_nodes).and_return([])

  #   expect(@bp.generate_destination_files).to eq []    
  # end
end