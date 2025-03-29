require 'json_to_csv_converter'
require 'csv'
require 'tempfile'

describe JsonToCsvConverter do
  describe '#flatten_profile' do
    let(:converter) { described_class.new('', '') }

    let(:complete_profile) do
      {
        "id" => 0,
        "email" => "email@test.com",
        "tags" => [
          "consectetur",
          "quis"
        ],
        "profiles" => {
          "facebook" => { "id" => 0, "picture" => "picture_fb" },
          "twitter" => { "id" => 0, "picture" => "picture_tw" }
        }
      }
    end

    let(:missing_tags_profile) do
      {
        "id" => 0,
        "email" => "email@test.com",
        "tags" => [],
        "profiles" => {
          "facebook" => {
            "id" => 0,
            "picture" => "picture_fb"
          },
          "twitter" => {
            "id" => 0,
            "picture" => "picture_tw"
          }
        }
      }
    end

    let(:nil_tags_profile) do
      {
        "id" => 0,
        "email" => "email@test.com",
        "tags" => nil,
        "profiles" => {
          "facebook" => {
            "id" => 0,
            "picture" => "picture_fb"
          },
          "twitter" => {
            "id" => 0,
            "picture" => "picture_tw"
          }
        }
      }
    end

    it "Correctly creates a csv row - flattens the profile - from the JSON" do
      expected = [0, "email@test.com", "consectetur,quis", 0, "picture_fb", 0, "picture_tw"]
      expect(converter.send(:flatten_profile, complete_profile)).to eq(expected)
    end

    it "handles missing tags" do
      expected = [0, "email@test.com", "", 0, "picture_fb", 0, "picture_tw"]
      expect(converter.send(:flatten_profile, missing_tags_profile)).to eq(expected)
    end

    it "handles tags equals to nil" do
      expected = [0, "email@test.com", "", 0, "picture_fb", 0, "picture_tw"]
      expect(converter.send(:flatten_profile, nil_tags_profile)).to eq(expected)
    end
  end

  describe 'convert' do
    let (:json) do
      [
        {
          "id" => 1,
          "email" => "a@mail.com",
          "tags" => ["a", "b"],
          "profiles" => {
            "facebook" => { "id" => 10, "picture" => "fb.png" },
            "twitter" => { "id" => 20, "picture" => "tw.png" }
          }
        },
        {
          "id" => 3,
          "email" => "c@mail.com",
          "tags" => ["d", "e"],
          "profiles" => {
            "twitter" => { "id" => 22, "picture" => "tw3.png" }
          }
        },
        {
          "id" => 4,
          "email" => "d@mail.com",
          "tags" => ["f", "g", "h"]
        }
      ].to_json
    end

    let (:json_invalid) do
      "{not valid}"
    end

    let (:json_string) do
      '"Winter is coming"'
    end

    let (:json_falsy_keys) do
      [
        {
          "name" => "Kobe",
          "username" => "BlackMamba"
        }
      ].to_json
    end

    let (:json_tricky) do
      ["Winter is coming"].to_json
    end

    let(:tmpfile) { Tempfile.new(['output', '.csv']) }
    let(:converter) { described_class.new(json, tmpfile.path) }

    after { tmpfile.close; tmpfile.unlink }

    it "writes the correct number of rows to the CSV file" do
      converter.convert

      csv = CSV.read(tmpfile.path)
      expect(csv.size).to eq(4)
    end

    it "writes a complete profile correctly for the first row" do
      converter.convert

      csv = CSV.read(tmpfile.path)
      expect(csv[1]).to eq(["1", "a@mail.com", "a,b", "10", "fb.png", "20", "tw.png"])
    end

    it "handles a profile missing a Facebook profile returning nil" do
      converter.convert

      csv = CSV.read(tmpfile.path)
      expect(csv[2]).to eq(["3", "c@mail.com", "d,e", nil, nil, "22", "tw3.png"])
    end

    it "handles totally missing profiles" do
      converter.convert

      csv = CSV.read(tmpfile.path)
      expect(csv[3]).to eq(["4", "d@mail.com", "f,g,h", nil, nil, nil, nil])
    end

    it "does not raise an error for invalid JSON" do
      converter = described_class.new(json_invalid, tmpfile.path)

      expect { converter.convert }.not_to raise_error
    end

    it "creates an empty file for invalid JSON" do
      converter = described_class.new(json_invalid, tmpfile.path)
      converter.convert

      expect(File.size(tmpfile.path)).to eq(0)
    end

    it "does not write anything in the CSV if the JSON is valid but not an array" do
      converter = described_class.new(json_string, tmpfile.path)

      expect { converter.convert }.not_to raise_error
    end

    it "creates an empty file for valid JSON (no array)" do
      converter = described_class.new(json_string, tmpfile.path)
      converter.convert

      expect(File.size(tmpfile.path)).to eq(0)
    end

    it "skips element without id and email keys" do
      converter = described_class.new(json_falsy_keys, tmpfile.path)

      expect { converter.convert }.not_to raise_error
    end

    it "skips non-hash elements in array" do
      converter = described_class.new(json_tricky, tmpfile.path)

      expect { converter.convert }.not_to raise_error
    end
  end
end
