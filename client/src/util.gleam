import lustre/attribute.{type Attribute, class}

pub fn hover_classes() -> Attribute(msg) {
  class("hover:opacity-70 transition-all duration-200")
}
