RSpec.describe MTIF::Post do
  it 'should have accessors for source and data' do
    expect(MTIF::Post.new([])).to respond_to(:source, :data)
  end
  
  context 'valid keys' do
    it 'should have a list of valid single-value keys' do
      expect(MTIF::Post).to have_constant('SINGLE_VALUE_KEYS')
      expect(MTIF::Post::SINGLE_VALUE_KEYS).not_to be_empty
    end

    it 'should have a list of valid keys which can have multiple values' do
      expect(MTIF::Post).to have_constant('MULTIVALUE_KEYS')
      expect(MTIF::Post::MULTIVALUE_KEYS).not_to be_empty
    end

    it 'should have a list of valid multiline keys' do
      expect(MTIF::Post).to have_constant('MULTILINE_KEYS')
      expect(MTIF::Post::MULTILINE_KEYS).not_to be_empty
    end

    it 'should not have any multivalue keys in the list of single-value keys or vice versa' do
      expect((MTIF::Post::MULTIVALUE_KEYS & MTIF::Post::SINGLE_VALUE_KEYS)).to be_empty
    end

    it 'should have a list of valid keys which is proper superset of these' do
      expect(MTIF::Post).to have_constant('VALID_KEYS')
      expect(MTIF::Post::VALID_KEYS).to match_array((MTIF::Post::SINGLE_VALUE_KEYS + MTIF::Post::MULTILINE_KEYS + MTIF::Post::MULTIVALUE_KEYS).uniq)
    end
    
    context 'key methods' do
      before :each do
        @post = MTIF::Post.new([])
      end
      
      subject {@post}

      it {should respond_to(:valid_keys)}
      context '#valid_keys' do
        subject {@post.valid_keys}
        
        it {should == MTIF::Post::VALID_KEYS}
      end

      it {should respond_to(:valid_key?)}
      context '#valid_key?' do
        it 'should be true when valid, false otherwise' do
          valid_key = @post.valid_keys.first.to_sym
          invalid_key = valid_key.to_s.reverse.to_sym

          expect(@post.valid_key?(valid_key)).to be_truthy
          expect(@post.valid_key?(valid_key.to_s)).to be_truthy
          expect(@post.valid_key?(invalid_key)).to be_falsey
          expect(@post.valid_key?(invalid_key.to_s)).to be_falsey
        end
      end

      context 'returning lists' do
        it {should respond_to(:single_line_single_value_keys)}
        context '#single_line_single_value_keys' do
          subject {@post.single_line_single_value_keys}
          
          it {should_not include(*MTIF::Post::MULTILINE_KEYS)}
          it {should_not include(*MTIF::Post::MULTIVALUE_KEYS)}
          it {should include(*(MTIF::Post::SINGLE_VALUE_KEYS - MTIF::Post::MULTILINE_KEYS))}
        end

        it {should respond_to(:single_line_multivalue_keys)}
        context '#single_line_multivalue_keys' do
          subject {@post.single_line_multivalue_keys}
          
          it {should_not include(*MTIF::Post::MULTILINE_KEYS)}
          it {should_not include(*MTIF::Post::SINGLE_VALUE_KEYS)}
          it {should include(*(MTIF::Post::MULTIVALUE_KEYS - MTIF::Post::MULTILINE_KEYS))}
        end

        it {should respond_to(:multiline_single_value_keys)}
        context '#multiline_single_value_keys' do
          subject {@post.multiline_single_value_keys}
          
          it {should_not include(*MTIF::Post::MULTIVALUE_KEYS)}
          it {should include(*(MTIF::Post::MULTILINE_KEYS & MTIF::Post::SINGLE_VALUE_KEYS))}
        end

        it {should respond_to(:multiline_multivalue_keys)}
        context '#multiline_multivalue_keys' do
          subject {@post.multiline_multivalue_keys}

          it {should_not include(*MTIF::Post::SINGLE_VALUE_KEYS)}
          it {should include(*(MTIF::Post::MULTILINE_KEYS & MTIF::Post::MULTIVALUE_KEYS))}
        end
      end
    end
  end
  
  context 'updating attributes via #method_missing' do
    before :each do
      @post = MTIF::Post.new(["ALLOW COMMENTS: 0\n"])
    end

    it 'should properly update values' do
      expect(@post.allow_comments).not_to eq(1)
      @post.allow_comments = 1
      expect(@post.allow_comments).to eq(1)
    end
    
  end

  context 'fetching data' do
    subject {MTIF::Post.new([])}
    
    MTIF::Post::VALID_KEYS.each do |key|
      it {should respond_to(key)}
      it {should respond_to("#{key}=")}
    end

    it {should_not respond_to(:this_is_not_a_valid_key)}
    it {should_not respond_to(:this_is_not_a_valid_key=)}

    it 'should default to arrays for multivalue keys' do
      post = MTIF::Post.new([])

      MTIF::Post::MULTIVALUE_KEYS.each do |key|
        expect(post.send(key)) == []
      end
    end
  end

  context 'parsing input' do
    before :each do
      @content = [
        "AUTHOR: The ----- Meyer Kids\n",
        "TITLE: Crazy Parents: -------- A Primer\n",
        "-----\n",
        "BODY:\n",
        "Start singing an obnoxious song and ----- never ----- stop.\n",
        "-----\n",
        "--------\n"
      ]

      @post = MTIF::Post.new(@content)
    end
    
    it 'should not notice separators that are not at the beginning of a line' do
      expect(@post.author).to eq("The ----- Meyer Kids")
      expect(@post.title).to eq("Crazy Parents: -------- A Primer")
      expect(@post.body).to eq("Start singing an obnoxious song and ----- never ----- stop.")
    end
  end

  context 'updating data' do
    subject {MTIF::Post.new([])}
    
    it 'should default to arrays for multivalue keys' do
      post = MTIF::Post.new([])

      MTIF::Post::MULTIVALUE_KEYS.each.with_index do |key, i|
        post.send((key.to_s + '=').to_sym, [i])
        expect(post.send(key)) == [i]
      end
    end
  end

  context '#to_mtif' do
    before :each do
      # TODO: refactor to remove ordering dependency
      @content = [
        "AUTHOR: The Meyer Kids\n",
        "TITLE: Crazy Parents: A Primer\n",
        "DATE: 06/19/1999 07:00:00 PM\n",
        "ALLOW COMMENTS: 0\n",
        "PRIMARY CATEGORY: Fun!\n",
        "CATEGORY: Fun!\n",
        "TAGS: \"Movable Type\",foo,bar\n",
        "-----\n",
        "BODY:\n",
        "Start singing an obnoxious song and never stop.\n",
        "-----\n",
        "COMMENT:\n",
        "AUTHOR: Jim Meyer\n",
        "EMAIL: \n",
        "IP: 67.180.21.185\n",
        "URL: http://profile.typepad.com/purp\n",
        "DATE: 08/26/2010 10:32:04 AM\n",
        "Yeah, that works.\n",
        "-----\n",
        "--------\n"
      ]

      @post = MTIF::Post.new(@content)
    end
    
    it 'should return concise MTIF containing only keys which are set' do
      expect(@post).to respond_to(:to_mtif)
      expect(@post.to_mtif).to eq(@content.join)
    end
  end
end
