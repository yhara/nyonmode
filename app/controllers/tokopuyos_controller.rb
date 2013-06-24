class TokopuyosController < ApplicationController
  before_action :set_tokopuyo, only: [:show, :edit, :update, :destroy]

  # GET /tokopuyos
  # GET /tokopuyos.json
  def index
    @tokopuyos = Tokopuyo.all
  end

  # GET /tokopuyos/1
  # GET /tokopuyos/1.json
  def show
  end

  # GET /tokopuyos/new
  def new
    @tokopuyo = Tokopuyo.new
  end

  # GET /tokopuyos/1/edit
  def edit
  end

  # POST /tokopuyos
  # POST /tokopuyos.json
  def create
    @tokopuyo = Tokopuyo.new(tokopuyo_params)

    respond_to do |format|
      if @tokopuyo.save
        format.html { redirect_to @tokopuyo, notice: 'Tokopuyo was successfully created.' }
        format.json { render action: 'show', status: :created, location: @tokopuyo }
      else
        format.html { render action: 'new' }
        format.json { render json: @tokopuyo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tokopuyos/1
  # PATCH/PUT /tokopuyos/1.json
  def update
    respond_to do |format|
      if @tokopuyo.update(tokopuyo_params)
        format.html { redirect_to @tokopuyo, notice: 'Tokopuyo was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @tokopuyo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tokopuyos/1
  # DELETE /tokopuyos/1.json
  def destroy
    @tokopuyo.destroy
    respond_to do |format|
      format.html { redirect_to tokopuyos_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tokopuyo
      @tokopuyo = Tokopuyo.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def tokopuyo_params
      params[:tokopuyo]
    end
end
