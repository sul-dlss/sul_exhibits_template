# frozen_string_literal: true

require 'bibtex'
require 'citeproc'

# Bibliography represents a bibliography that can be rendered as HTML
# using BibTeX and CiteProc
class Bibliography
  attr_reader :bibliography

  # @param [BibTeX::Bibliography|Pathname|String] `bibliography`
  def initialize(bibliography)
    @bibliography = case bibliography
                    when Pathname
                      to_bibtex(bibliography.read)
                    when String
                      to_bibtex(bibliography)
                    when BibTeX::Bibliography
                      bibliography
                    else
                      raise ArgumentError, 'Unsupported type'
                    end
  end

  def to_html
    render
  end

  private

  # Renders a *sorted* bibliography
  def render(format = 'html')
    cp = CiteProc::Processor.new(style: 'chicago-author-date', format:)
    cp.import bibliography.to_citeproc
    cp.bibliography.join
  end

  # @return [BibTeX::Bibliography]
  def to_bibtex(bibtex_data)
    BibTeX.parse(preprocess(bibtex_data), filter: :latex)
  end

  def preprocess(bibtex_data)
    # BibTeX.parse `filter: latex` doesn't handle these cases correctly
    bibtex_data.gsub!(/\\textbackslash/i, '')
    bibtex_data.gsub!(/\\textit/i, '')
    bibtex_data.gsub!(/\\textbar/i, '|')

    bibtex_data
  end
end
