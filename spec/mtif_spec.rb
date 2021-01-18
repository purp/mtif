RSpec.describe MTIF do
  it 'should have a version number' do
    expect {MTIF::VERSION}.not_to raise_error
  end

  context "#initialize" do
    context 'without content' do
      it 'should fail' do
        expect {MTIF.new}.to raise_error(ArgumentError)
      end
    end

    context 'with content' do
      it 'should divide the content into posts' do
        expect(MTIF::Post).to receive(:new).exactly(3).times.and_return(instance_double("MTIF::Post"))

        mtif = MTIF.new(['-' * 8] * 3)

        expect {mtif.posts}.not_to raise_error
        expect mtif.posts.size == 3
      end
      
      it 'should convert itself back to MTIF' do
        post_mtif = "THIS IS: not valid MTIF\n--------\n"

        post = instance_double("MTIF::Post")
        expect(post).to receive(:to_mtif).once.and_return(post_mtif)
        
        mtif = MTIF.new([])
        mtif.posts = [post]

        expect {@mtif_output = mtif.to_mtif}.not_to raise_error
        expect @mtif_output == post_mtif
      end
    end

    context ".load_file" do
      it 'should return an MTIF object' do
        expect(MTIF::Post).to receive(:new).twice.and_return(instance_double("MTIF::Post"))
    
        file_instance = instance_double("File")
        expect(file_instance).to receive(:readlines).once.and_return(['-' * 8, '-' * 8])
        expect(file_instance).to receive(:close).once

        expect(File).to receive(:open).once.and_return(file_instance)

        expect {mtif = MTIF.load_file('/youre/in/a/maze/of/twisty/passages/all/alike')}.not_to raise_error
      end
    end

    context "#save_file" do
      it 'should create a file with the content in it' do          
        mtif_output = "THIS IS: not valid MTIF\n--------\n"

        post = instance_double("MTIF::Post")
        expect(post).to receive(:to_mtif).once.and_return(mtif_output)
        
        mtif = MTIF.new([])
        mtif.posts = [post]

        file_instance = instance_double("File")
        expect(file_instance).to receive(:<<).with(mtif_output).once
        expect(file_instance).to receive(:close).once

        expect(File).to receive(:open).once.and_return(file_instance)

        expect {mtif.save_file('/youre/in/a/maze/of/twisty/passages/all/different')}.not_to raise_error
      end
    end
  end
end