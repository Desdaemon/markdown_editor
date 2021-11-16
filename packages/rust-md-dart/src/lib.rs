mod api;

#[cfg(not(target_arch = "wasm32"))]
mod bridge_generated;

#[cfg(target_arch = "wasm32")]
mod web;
