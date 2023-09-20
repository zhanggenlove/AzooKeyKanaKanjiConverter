//
//  prediction.swift
//  
//
//  Created by miwa on 2023/09/19.
//

import Foundation

extension Kana2Kanji {
    func mergeCandidates(_ left: Candidate, _ right: Candidate) -> Candidate {
        guard let leftLast = left.data.last, let rightFirst = right.data.first else {
            return Candidate(
                text: left.text + right.text,
                value: left.value + right.value,
                correspondingCount: left.correspondingCount + right.correspondingCount,
                lastMid: right.lastMid,
                data: left.data + right.data
            )
        }
        let ccValue = self.dicdataStore.getCCValue(leftLast.lcid, rightFirst.lcid)
        let includeMMValueCalculation = DicdataStore.includeMMValueCalculation(rightFirst)
        let mmValue = includeMMValueCalculation ? self.dicdataStore.getMMValue(left.lastMid, rightFirst.mid):.zero
        let newValue = left.value + mmValue + ccValue + right.value
        return Candidate(
            text: left.text + right.text,
            value: newValue,
            correspondingCount: left.correspondingCount + right.correspondingCount,
            lastMid: right.lastMid,
            data: left.data + right.data
        )
    }

    func getPredictionCandidates(prepart: Candidate, N_best: Int) -> [PredictionCandidate] {
        var result: [PredictionCandidate] = []
        var count = 1
        var prefixCandidate = prepart
        prefixCandidate.actions = []
        var prefixCandidateData = prepart.data
        var totalWord = ""
        var totalRuby = ""
        var totalData: [DicdataElement] = []
        while count <= min(prepart.data.count, 3), let element = prefixCandidateData.popLast() {
            defer {
                count += 1
            }
            // prefixCandidateを更新する
            do {
                prefixCandidate.value -= element.value()
                prefixCandidate.value -= self.dicdataStore.getCCValue(prefixCandidateData.last?.rcid ?? CIDData.BOS.cid, element.lcid)
                if DicdataStore.includeMMValueCalculation(element) {
                    let previousMid = prefixCandidateData.last(where: DicdataStore.includeMMValueCalculation)?.mid ?? MIDData.BOS.mid
                    prefixCandidate.lastMid = previousMid
                    prefixCandidate.value -= self.dicdataStore.getMMValue(previousMid, element.mid)
                }
                prefixCandidate.data = prefixCandidateData
                
                prefixCandidate.text = prefixCandidateData.reduce(into: "") { $0 += $1.word }
                prefixCandidate.correspondingCount = prefixCandidateData.reduce(into: 0) { $0 += $1.ruby.count }
            }

            
            totalWord.insert(contentsOf: element.word, at: totalWord.startIndex)
            totalRuby.insert(contentsOf: element.ruby, at: totalRuby.startIndex)
            totalData.insert(element, at: 0)
            let dicdata = self.dicdataStore.getPredictionLOUDSDicdata(key: totalRuby).filter {
                DicdataStore.predictionUsable[$0.rcid] && $0.word.hasPrefix(totalWord)
            }
            
            for data in dicdata {
                let ccValue = self.dicdataStore.getCCValue(prefixCandidateData.last?.rcid ?? CIDData.BOS.cid, data.lcid)
                let includeMMValueCalculation = DicdataStore.includeMMValueCalculation(data)
                let mmValue = includeMMValueCalculation ? self.dicdataStore.getMMValue(prefixCandidate.lastMid, data.mid):.zero
                let wValue = data.value()
                let newValue = prefixCandidate.value + mmValue + ccValue + wValue
                // 追加すべきindexを取得する
                let lastindex: Int = (result.lastIndex(where: {$0.value >= newValue}) ?? -1) + 1
                if lastindex == N_best {
                    continue
                }
                // カウントがオーバーしている場合は除去する
                if result.count >= N_best {
                    result.removeLast()
                }
                // 共通接頭辞を切り落とす
                let text = String(data.word.dropFirst(totalWord.count))
                result.insert(.replacement(.init(text: text, targetData: totalData, replacementData: [data], value: newValue)), at: lastindex)
            }
        }
        return result
    }

    /// 入力がない状態から、妥当な候補を探す
    /// - parameters:
    ///   - preparts: Candidate列。以前確定した候補など
    ///   - N_best: 取得する候補数
    /// - returns:
    ///   ゼロヒント予測変換の結果
    /// - note:
    ///   「食べちゃ-てる」「食べちゃ-いる」などの間抜けな候補を返すことが多いため、学習によるもの以外を無効化している。
    func getZeroHintPredictionCandidates(preparts: some Collection<Candidate>, N_best: Int) -> [PredictionCandidate] {
        var result: [PredictionCandidate] = []
        for candidate in preparts {
            if let last = candidate.data.last {
                let dicdata = self.dicdataStore.getZeroHintPredictionDicdata(lastRcid: last.rcid)
                for data in dicdata {
                    let ccValue = self.dicdataStore.getCCValue(last.rcid, data.lcid)
                    let includeMMValueCalculation = DicdataStore.includeMMValueCalculation(data)
                    let mmValue = includeMMValueCalculation ? self.dicdataStore.getMMValue(candidate.lastMid, data.mid):.zero
                    let wValue = data.value()
                    let newValue = candidate.value + mmValue + ccValue + wValue

                    // 追加すべきindexを取得する
                    let lastindex: Int = (result.lastIndex(where: {$0.value >= newValue}) ?? -1) + 1
                    if lastindex == N_best {
                        continue
                    }
                    // カウントがオーバーしている場合は除去する
                    if result.count >= N_best {
                        result.removeLast()
                    }
                    result.insert(.additional(.init(text: data.word, data: [data], value: newValue)), at: lastindex)
                }
            }
        }
        return result
    }

}
