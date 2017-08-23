// https://github.com/servo/html5ever/blob/master/html5ever/examples/noop-tree-builder.rs

use html5ever::tree_builder::{ElementFlags, NodeOrText, QuirksMode, TreeSink};
use html5ever::{Attribute, ExpandedName, QualName};
use html5ever::tendril::StrTendril;
use std::collections::HashMap;
use std::borrow::Cow;

pub struct NoopTreeSink {
    next_id: usize,
    names: HashMap<usize, QualName>,
}

impl Default for NoopTreeSink {
    fn default() -> Self {
        NoopTreeSink {
            next_id: 1,
            names: HashMap::new(),
        }
    }
}

impl NoopTreeSink {
    fn get_id(&mut self) -> usize {
        let id = self.next_id;
        self.next_id += 2;
        id
    }
}

impl TreeSink for NoopTreeSink {
    type Handle = usize;
    type Output = Self;

    fn finish(self) -> Self {
        self
    }

    fn get_document(&mut self) -> usize {
        0
    }

    fn get_template_contents(&mut self, target: &usize) -> usize {
        if let Some(expanded_name!(html "template")) = self.names.get(target).map(|n| n.expanded())
        {
            target + 1
        } else {
            panic!("not a template element")
        }
    }

    fn same_node(&self, x: &usize, y: &usize) -> bool {
        x == y
    }

    fn elem_name(&self, target: &usize) -> ExpandedName {
        self.names.get(target).expect("not an element").expanded()
    }

    fn create_element(&mut self, name: QualName, _: Vec<Attribute>, _: ElementFlags) -> usize {
        let id = self.get_id();
        self.names.insert(id, name);
        id
    }

    fn create_comment(&mut self, _text: StrTendril) -> usize {
        self.get_id()
    }

    #[allow(unused_variables)]
    fn create_pi(&mut self, target: StrTendril, value: StrTendril) -> usize {
        unimplemented!()
    }

    fn append_before_sibling(&mut self, _sibling: &usize, _new_node: NodeOrText<usize>) {}

    fn parse_error(&mut self, _msg: Cow<'static, str>) {}

    fn set_quirks_mode(&mut self, _mode: QuirksMode) {}

    fn append(&mut self, _parent: &usize, _child: NodeOrText<usize>) {}

    fn append_doctype_to_document(&mut self, _: StrTendril, _: StrTendril, _: StrTendril) {}

    fn add_attrs_if_missing(&mut self, target: &usize, _attrs: Vec<Attribute>) {
        assert!(self.names.contains_key(target), "not an element");
    }

    fn remove_from_parent(&mut self, _target: &usize) {}

    fn reparent_children(&mut self, _node: &usize, _new_parent: &usize) {}

    fn mark_script_already_started(&mut self, _node: &usize) {}

    fn append_based_on_parent_node(
        &mut self,
        _element: &usize,
        _prev_element: &usize,
        _new_node: NodeOrText<usize>,
    ) {
    }
}
