require 'securerandom'
require 'rqrcode'

class FormsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]

  def index
    @forms = policy_scope(Form).order(created_at: :desc)
  end

  def show
    @form = Form.find(params[:id])
    @questions = Question.where(form_id: @form)
    #@answers = Answer.where(params[:question_id])
    authorize @form
  end

  def new
    @form = Form.new
    authorize @form
    @question = Question.new
    @questions = Question.where(predefined: true)
  end

  def create
    @questions = Question.where(predefined: true)
    @form = Form.new(form_params)
    @form.user = current_user
    @form.presentation_key = SecureRandom.alphanumeric(5)
    authorize @form
    if @form.save
      # need to connect question with form_question if needed
      @question = Question.new(question_params)
      @question.predefined = false
      if @question.save
        redirect_to edit_form_path(@form)
      else
        render :new
      end
    else
      render :new
    end
  end

  def edit
    @questions = Question.where(predefined: true)
    @form = Form.find(params[:id])
    authorize @form
  end

  def update
    @questions = Question.where(predefined: true)
    @form = Form.find(params[:id])
    authorize @form
    if @form.update(form_params)
      question_content = params[:question_content]
      question_type = params[:question_type]
      question_topic = params[:question_topic]
      @question = Question.new(question_content: question_content, question_type: question_type, question_topic: question_topic, predefined: false)
      if @question.save
        redirect_to forms_path
      else
        render :new
      end
    end
  end
  
  def success
    @form = Form.find(params[:id])
    authorize @form
    @qr = RQRCode::QRCode.new( "http://localhost:3000/forms/#{@form.id}/answers/new", :size => 4, :level => :h )
  end

  private

  def form_params
    params.require(:form).permit(:name, :presented_on, :speaker)
  end

  def question_params
    params.require(:question).permit(:question_content, :question_topic, :question_type)
  end

end
