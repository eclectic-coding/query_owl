class WidgetsController < ApplicationController
  # Intentionally triggers an N+1 — loads each widget's tags in a loop.
  def index
    widgets = Widget.all.to_a
    data = widgets.map { |w| { id: w.id, name: w.name, tags: w.tags.map(&:name) } }
    render json: data
  end

  # Demonstrates unused eager load — includes tags but never accesses them.
  def unused
    widgets = Widget.includes(:tags).to_a
    render json: widgets.map { |w| { id: w.id, name: w.name } }
  end

  def show
    render json: Widget.find(params[:id])
  end
end