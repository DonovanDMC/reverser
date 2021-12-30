module Sites
  module Definitions
    module Commishes
      module_function

      def enum_value
        "commishes"
      end

      def display_name
        "Commishes"
      end

      def homepage
        "https://commishes.com/"
      end

      def gallery_templates
        [
          "portfolio.commishes.com/user/{site_artist_identifier}",
          "ych.commishes.com/user/{site_artist_identifier}",
        ]
      end

      def username_identifier_regex
        /[a-zA-Z0-9_\-]{3,20}/
      end
    end
  end
end