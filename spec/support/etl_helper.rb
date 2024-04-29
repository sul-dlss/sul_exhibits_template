# frozen_string_literal: true

# :nodoc:
module EtlHelper
  # Helper method to get indexed documents for a resource
  def indexed_documents(resource, throw_as: :skip, on_error: :exception)
    return to_enum(:indexed_documents, resource, throw_as:, on_error: :exception) unless block_given?

    resource.reindex(on_error:) do |data|
      yield data
      throw throw_as if throw_as
    end
  end
end
