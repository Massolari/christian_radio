import lustre/attribute.{type Attribute, class}

pub fn hover_classes() -> Attribute(msg) {
  class("hover:opacity-70 transition-opacity duration-200")
}

pub fn active_classes() -> Attribute(msg) {
  class("transition-transform active:duration-100 active:scale-50")
}
