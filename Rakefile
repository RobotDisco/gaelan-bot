task :archive do
    sh 'ebooks archive NaleagDeco'
end

task :consume do
    sh 'ebooks consume corpus/NaleagDeco.json'
end

task default: %w[archive consume]
