# frozen_string_literal: true

class ExportsController < ApplicationController
  require "csv"
  require "securerandom"
  require "json"

  def gerar_csv
    return render json: { error: "Content-Type must be application/json" }, status: :bad_request unless json_request?

    payload = JSON.parse(request.body.read)
    transacoes = process_transactions(payload)
    send_csv_data(generate_csv(transacoes))
  end

  private

  def json_request?
    request.content_type == "application/json"
  end

  def gerar_identificacao_unica
    SecureRandom.uuid
  end

  def process_transactions(payload)
    transacoes = payload.flat_map do |transacao|
      transacao["parcelas_detalhadas"].present? ? process_parcelas(transacao) : [process_parcela_unica(transacao)]
    end

    agrupar_e_ordenar(transacoes)
  end

  def process_parcelas(transacao)
    transacao["parcelas_detalhadas"].map do |parcela|
      build_transacao(transacao, Date.parse(parcela["data_liquidacao"]), parcela["valor"].to_f)
    end
  end

  def process_parcela_unica(transacao)
    build_transacao(transacao, Date.parse(transacao["data_compra"]) + 30.days, transacao["valor_total"].to_f)
  end

  def build_transacao(transacao, data_liquidacao, valor_total)
    {
      "bandeira" => transacao["bandeira"],
      "cnpj_lojista" => transacao["cnpj_lojista"],
      "data_liquidacao" => data_liquidacao,
      "valor_total" => valor_total
    }
  end

  def agrupar_e_ordenar(transacoes)
    agrupadas = transacoes.group_by { |t| [t["bandeira"], t["data_liquidacao"], t["cnpj_lojista"]] }

    agrupadas_transformadas = agrupadas.map do |(bandeira, data_liquidacao, cnpj_lojista), grupo|
      {
        "identificacao_unica" => gerar_identificacao_unica,
        "bandeira" => bandeira,
        "cnpj_lojista" => cnpj_lojista,
        "data_liquidacao" => data_liquidacao,
        "valor_total" => grupo.sum { |t| t["valor_total"] }
      }
    end

    agrupadas_transformadas.sort_by { |t| [t["bandeira"], t["data_liquidacao"], t["cnpj_lojista"]] }
  end

  def generate_csv(transacoes)
    CSV.generate(headers: true) do |csv|
      csv << %w[identificacao_unica bandeira cnpj_lojista data_liquidacao valor_total]
      transacoes.each { |t| csv << t.values_at(*csv.headers) }
    end
  end

  def send_csv_data(csv)
    send_data csv,
              type: "text/csv; charset=utf-8",
              disposition: "attachment; filename=transacoes.csv"
  end
end
