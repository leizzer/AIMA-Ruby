require 'search'

ACCIONES = [[0, 1], [0, -1], [1, 0], [-1, 0]]

class ProblemaRompenumeros < Problem
  def successor(state)
    dimension = state.split('|').length
    x, y = obtener_posicion state, '.'
    return ACCIONES.collect do |a|
              if (0 <= (x + a[0]) && (x + a[0]) < dimension) && (0 <= (y + a[1]) && (y + a[1]) < dimension)
                [a, obtener_sucesor(state, a)]
              end
            end.compact
  end

  def goal_test(state)
    state == "1,2,3|4,5,6|7,8,."
  end

  def obtener_posicion(estado, elemento)
    filas = estado.split '|'
    y = 0
    x = 0
    filas.each do |fila|
                 y = filas.index(fila) if fila.split(',').include? elemento
                end
    x = filas[y].split(',').index elemento

    return x, y
  end

  def obtener_sucesor(estado, accion)
    x, y = obtener_posicion estado, '.'

    numero_mover = estado.split('|')[y + accion[1]].split(',')[x + accion[0]]
    estado = estado.sub ".", "#"
    estado = estado.sub(/#{numero_mover}/, ".")
    estado = estado.sub('#', numero_mover)

    return estado
  end

  def h(node)
    distancias = []
    filas = node.state.split '|'
    meta = generar_inicial(filas.length, false)
    distancia = lambda {|p1, p2| (p1[0] - p2[0]).abs + (p1[1] - p2[1]).abs }

    filas.map! do |f|
      distancias.concat f.split(',').collect do |elemento|
                                            [distnacia(obtener_posicion(node.state, elemento), obtener_posicion(meta,elemento))]  unless elemento == "."
                                          end
    end

    sum = 0
    distancias.each {|d| sum += d.to_i}
    return sum
  end
end


def generar_inicial(dimension, mezclar)
  numeros = (0..(dimension ** 2) - 1).to_a
  numeros << '.'
  numeros.shuffle! if mezclar

  estado = []

  (0..dimension).to_a.map do |i|
                            estado << numeros[i * dimension, dimension]
                          end

  estado = estado.each do |fila|
                          [fila.each do |elemento|
                                        [elemento.to_s]
                                  end.join(',')]
                              end.join('|')

  return estado
end



if ARGV[0].include? '|'
  inicial = ARGV[0]
else
#  inicial = generar_inicial(ARGV[1].to_i, true)
end

pp = ProblemaRompenumeros.new(inicial)

puts "Rompecabezas:"
puts inicial
puts "Resolviendo..."
puts astar_search(pp, pp.method(:h)) #esta andando mal la llamada a astar, asi que tengo que poner el metodo a mano

