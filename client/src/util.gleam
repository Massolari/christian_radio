import lustre/attribute.{type Attribute, class}

pub fn hover_classes() -> Attribute(msg) {
  class("hover:opacity-70 transition-opacity duration-200")
}

pub fn group_active_classes() -> Attribute(msg) {
  class("transition-transform group-active:duration-100 group-active:scale-50")
}
